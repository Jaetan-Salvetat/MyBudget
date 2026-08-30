library;

import 'decode_roles.dart';
import 'fuse_passes.dart';
import 'line_features.dart';
import 'lines.dart';
import 'role_tagger.dart' show predictedRoles;
import 'structure.dart';
import 'structure_roles.dart';

enum ReadSource { pass1, retry, fused, confirm }

const Set<ReadSource> verifiedSources = {
  ReadSource.pass1,
  ReadSource.retry,
  ReadSource.fused,
};

typedef RoleInference = List<List<double>> Function(List<PhysicalLine> lines);

class ReceiptRead {
  ReceiptRead(
    this.source,
    this.lines,
    this._inferRoles, {
    this.alternatives = const {},
  }) : merged = mergedLines(lines);

  final ReadSource source;
  final List<PhysicalLine> lines;
  final List<PhysicalLine> merged;
  final Map<int, int> alternatives;
  final RoleInference _inferRoles;

  List<List<double>>? _roles;

  List<List<double>> get roles => _roles ??= _inferRoles(lines);
}

class ReadTrace {
  const ReadTrace({
    required this.source,
    required this.lines,
    required this.merged,
    required this.roles,
    required this.decoding,
  });

  final ReadSource source;
  final List<PhysicalLine> lines;
  final List<PhysicalLine> merged;
  final List<List<double>> roles;
  final ReceiptDecoding decoding;

  bool get proved => decoding.receipt != null && decoding.receipt!.checksumOk;
}

class LocalOutcome {
  const LocalOutcome({
    required this.source,
    required this.items,
    required this.total,
    required this.lines,
    required this.roles,
    this.trace = const [],
  });

  final ReadSource source;
  final List<ExtractedItem> items;
  final double? total;

  final List<PhysicalLine> lines;
  final List<List<double>> roles;

  final List<ReadTrace> trace;

  bool get verified => verifiedSources.contains(source);
}

ReadTrace traceOf(ReceiptRead read) => ReadTrace(
  source: read.source,
  lines: read.lines,
  merged: read.merged,
  roles: read.roles,
  decoding: decodeRoleConstrained(
    read.merged,
    read.roles,
    alternatives: read.alternatives,
  ),
);

ExtractedReceipt? readReceipt(ReceiptRead read) {
  final receipt = extractRoleConstrained(
    read.merged,
    read.roles,
    alternatives: read.alternatives,
  );
  return receipt != null && receipt.checksumOk ? receipt : null;
}

LocalOutcome unverified(ReceiptRead read, {List<ReadTrace> trace = const []}) {
  final receipt = extractRoles(read.merged, predictedRoles(read.roles));
  return LocalOutcome(
    source: ReadSource.confirm,
    items: receipt?.items ?? const [],
    total: receipt?.total,
    lines: read.lines,
    roles: read.roles,
    trace: trace,
  );
}

LocalOutcome _verified(
  ReceiptRead read,
  ExtractedReceipt receipt,
  List<ReadTrace> trace,
) => LocalOutcome(
  source: read.source,
  items: receipt.items,
  total: receipt.verifiedTotal,
  lines: read.lines,
  roles: read.roles,
  trace: trace,
);

typedef SecondPass = Future<List<PhysicalLine>?> Function();

Future<LocalOutcome> decideLocal(
  List<PhysicalLine> pass1,
  RoleInference inferRoles, {
  SecondPass? secondPass,
}) async {
  final trace = <ReadTrace>[];

  LocalOutcome? attempt(ReceiptRead read) {
    final step = traceOf(read);
    trace.add(step);
    return step.proved ? _verified(read, step.decoding.receipt!, trace) : null;
  }

  final first = ReceiptRead(ReadSource.pass1, pass1, inferRoles);
  final proved = attempt(first);
  if (proved != null) return proved;
  if (secondPass == null) return unverified(first, trace: trace);

  final retryLines = await secondPass();
  if (retryLines == null || retryLines.isEmpty) {
    return unverified(first, trace: trace);
  }

  final retry = ReceiptRead(ReadSource.retry, retryLines, inferRoles);
  final retryProved = attempt(retry);
  if (retryProved != null) return retryProved;

  final fusion = fusePasses(pass1, retryLines);
  final fused = ReceiptRead(
    ReadSource.fused,
    fusion.lines,
    inferRoles,
    alternatives: fusion.alternatives,
  );
  final fusedProved = attempt(fused);
  if (fusedProved != null) return fusedProved;
  return unverified(fused, trace: trace);
}
