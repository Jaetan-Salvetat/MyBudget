library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'invariants.dart';
import 'line_features.dart';
import 'lines.dart';
import 'structure.dart';

const int labelItem = 0;
const int labelDiscount = 1;
const int labelTotal = 2;
const int labelPayment = 3;
const int labelIgnore = 4;

const int centsCap = 500000;
const int negativeCap = 50000;
const double defaultMinProb = 0.02;
const int defaultMaxReferences = 4;
const double defaultMinReferenceProb = 0.5;
const double _probabilityFloor = 1e-12;
const List<int> labelOrder = [labelItem, labelDiscount, labelIgnore];

const double candidateProb = 0.5;
const double softIgnoreProb = 0.5;
const double evidenceProb = 0.5;
const double totalLineProbFloor = 0.1;
const double concordanceBonus = 1.5;
const int singleItemMinSources = 2;
const Set<EvidenceSource> arithmeticSources = {
  EvidenceSource.tax,
  EvidenceSource.paymentChange,
};

class LineOptions {
  const LineOptions({
    required this.cents,
    required this.logProbs,
    this.candidates = const [],
  });

  final int cents;
  final Map<int, double> logProbs;
  final List<int> candidates;

  List<(int, int, double)> variants() {
    final amounts = candidates.isEmpty ? [cents] : candidates;
    return [
      for (final (rank, cents) in amounts.indexed)
        (rank, cents, rank * math.log(candidateProb)),
    ];
  }
}

const LineOptions forcedIgnoreOption = LineOptions(
  cents: 0,
  logProbs: {labelIgnore: 0.0},
);

class Assignment {
  const Assignment(this.labels, this.cents);

  final List<int> labels;
  final List<int> cents;
}

class Reference {
  const Reference({
    required this.cents,
    required this.cutoffRank,
    required this.role,
    required this.logProb,
    required this.sources,
    required this.lineRank,
  });

  final int cents;
  final int cutoffRank;
  final int role;
  final double logProb;
  final List<EvidenceSource> sources;
  final int? lineRank;
}

class Hypothesis {
  const Hypothesis({
    required this.referenceCents,
    required this.referenceRole,
    required this.labels,
    required this.logProb,
    this.sources = const [],
    this.singleItem = false,
    this.cents = const [],
  });

  final int referenceCents;
  final int referenceRole;
  final List<int> labels;
  final double logProb;
  final List<EvidenceSource> sources;
  final bool singleItem;
  final List<int> cents;
}

int _discountCapacity(List<LineOptions> lines, double floor) {
  var capacity = 0;
  for (final line in lines) {
    final logProb = line.logProbs[labelDiscount];
    if (logProb != null && logProb >= floor) {
      var widest = 0;
      for (final (_, cents, _) in line.variants()) {
        widest = math.max(widest, cents.abs());
      }
      capacity += widest;
    }
  }
  return capacity;
}

int _contribution(int label, int cents) {
  if (label == labelItem) return cents;
  if (label == labelDiscount) return -cents.abs();
  return 0;
}

int _variantCount(List<LineOptions> lines) => lines.fold(
  1,
  (widest, line) => math.max(widest, line.variants().length),
);

int _encode(int label, int variant, int variantCount) =>
    label * variantCount + variant;

(int, int) _decodeChoice(int choice, int variantCount) =>
    (choice ~/ variantCount, choice % variantCount);

Assignment? bestAssignmentDetail(
  List<LineOptions> lines,
  int targetCents, {
  double minProb = 0.0,
}) {
  if (lines.isEmpty) return targetCents == 0 ? const Assignment([], []) : null;
  if (targetCents < 0 || targetCents > centsCap) return null;
  final floor = minProb > 0 ? math.log(minProb) : double.negativeInfinity;
  final discountCapacity = math.min(
    _discountCapacity(lines, floor),
    negativeCap,
  );
  final size = targetCents + 2 * discountCapacity + 1;
  final offset = discountCapacity;
  var scores = Float64List(size)..fillRange(0, size, double.negativeInfinity);
  scores[offset] = 0.0;
  final variantCount = _variantCount(lines);
  final choices = [
    for (var i = 0; i < lines.length; i++)
      Int16List(size)..fillRange(0, size, -1),
  ];

  for (final (index, line) in lines.indexed) {
    final next = Float64List(size)..fillRange(0, size, double.negativeInfinity);
    for (final label in labelOrder) {
      final logProb = line.logProbs[label];
      if (logProb == null || logProb < floor) continue;
      for (final (variant, cents, penalty) in line.variants()) {
        final shift = _contribution(label, cents);
        if (shift.abs() >= size) continue;
        final gain = logProb + penalty;
        final choice = _encode(label, variant, variantCount);
        if (shift >= 0) {
          for (var position = shift; position < size; position++) {
            final candidate = scores[position - shift] + gain;
            if (candidate > next[position]) {
              next[position] = candidate;
              choices[index][position] = choice;
            }
          }
        } else {
          for (var position = 0; position < size + shift; position++) {
            final candidate = scores[position - shift] + gain;
            if (candidate > next[position]) {
              next[position] = candidate;
              choices[index][position] = choice;
            }
          }
        }
      }
    }
    scores = next;
  }

  var position = targetCents + offset;
  if (position < 0 || position >= size || scores[position].isInfinite) {
    return null;
  }
  final labels = <int>[];
  final amounts = <int>[];
  for (var index = lines.length - 1; index >= 0; index--) {
    final (label, variant) = _decodeChoice(
      choices[index][position],
      variantCount,
    );
    final cents = lines[index].variants()[variant].$2;
    labels.add(label);
    amounts.add(cents);
    position -= _contribution(label, cents);
  }
  return Assignment(labels.reversed.toList(), amounts.reversed.toList());
}

List<int>? bestAssignment(
  List<LineOptions> lines,
  int targetCents, {
  double minProb = 0.0,
}) => bestAssignmentDetail(lines, targetCents, minProb: minProb)?.labels;

int _toCents(double price) => (price * 100).round();

double _logOf(double probability) =>
    math.log(math.max(probability, _probabilityFloor));

List<LineOptions> lineOptions(
  List<PricedLine> lines,
  List<List<double>> probas,
  int cutoffRank, {
  Set<int> forcedIgnore = const {},
  int? referenceRank,
  bool argmaxOnly = false,
  Map<int, int> alternatives = const {},
  Set<int> softIgnore = const {},
}) {
  final options = <LineOptions>[];
  for (final (rank, priced) in lines.indexed) {
    final cents = _toCents(priced.price);
    if (rank == referenceRank ||
        forcedIgnore.contains(rank) ||
        cents == 0 ||
        rank > cutoffRank) {
      options.add(forcedIgnoreOption);
      continue;
    }
    final row = probas[rank];
    var skip = math.max(
      row[labelIgnore],
      math.max(row[labelTotal], row[labelPayment]),
    );
    if (softIgnore.contains(rank)) skip = math.max(skip, softIgnoreProb);
    var logProbs = <int, double>{
      labelDiscount: _logOf(row[labelDiscount]),
      labelIgnore: _logOf(skip),
    };
    if (cents > 0) logProbs[labelItem] = _logOf(row[labelItem]);
    if (argmaxOnly) {
      int? bestLabel;
      for (final label in labelOrder) {
        final value = logProbs[label];
        if (value == null) continue;
        if (bestLabel == null || value > logProbs[bestLabel]!) {
          bestLabel = label;
        }
      }
      logProbs = {bestLabel!: logProbs[bestLabel]!};
    }
    options.add(
      LineOptions(
        cents: cents,
        logProbs: logProbs,
        candidates: _candidates(priced, cents, alternatives[rank]),
      ),
    );
  }
  return options;
}

List<int> _candidates(PricedLine priced, int cents, int? alternative) {
  final readings = [
    for (final price in priced.candidates) _toCents(price),
    ?alternative,
  ];
  final positive = cents > 0;
  final kept = <int>[];
  for (final reading in readings) {
    if (reading == 0 || (reading > 0) != positive || kept.contains(reading)) {
      continue;
    }
    kept.add(reading);
  }
  return kept;
}

List<Reference> _classifierReferences(
  List<PricedLine> lines,
  List<List<double>> probas,
  Constraints structure,
  double minReferenceProb,
) => [
  for (final rank in structure.referenceRanks.toList()..sort())
    if (probas[rank][labelTotal] >= minReferenceProb && lines[rank].price > 0)
      Reference(
        cents: _toCents(lines[rank].price),
        cutoffRank: rank,
        role: labelTotal,
        logProb: math.log(probas[rank][labelTotal]),
        sources: const [EvidenceSource.classifier],
        lineRank: rank,
      ),
];

List<Reference> _evidenceReferences(
  List<List<double>> probas,
  Constraints structure,
) => [
  for (final evidence in structure.evidences)
    Reference(
      cents: evidence.cents,
      cutoffRank: evidence.cutoffRank,
      role: labelTotal,
      logProb: math.log(
        evidence.source == EvidenceSource.totalLine
            ? math.max(
                probas[evidence.lineRank!][labelTotal],
                totalLineProbFloor,
              )
            : evidenceProb,
      ),
      sources: [evidence.source],
      lineRank: evidence.lineRank,
    ),
];

List<Reference> mergeReferences(List<Reference> references) {
  final byCents = <int, List<Reference>>{};
  for (final reference in references) {
    if (reference.cents > 0) {
      byCents.putIfAbsent(reference.cents, () => []).add(reference);
    }
  }
  final merged = <Reference>[];
  for (final entry in byCents.entries) {
    final group = entry.value;
    final sources = <EvidenceSource>[];
    for (final reference in group) {
      for (final source in reference.sources) {
        if (!sources.contains(source)) sources.add(source);
      }
    }
    final printed = group.where((r) => r.lineRank != null).toList();
    final anchor = printed.isNotEmpty
        ? printed.first
        : group.reduce((a, b) => a.cutoffRank <= b.cutoffRank ? a : b);
    var best = double.negativeInfinity;
    for (final reference in group) {
      best = math.max(best, reference.logProb);
    }
    merged.add(
      Reference(
        cents: entry.key,
        cutoffRank: anchor.cutoffRank,
        role: labelTotal,
        logProb: best + (sources.length - 1) * concordanceBonus,
        sources: sources,
        lineRank: anchor.lineRank,
      ),
    );
  }
  final indexed = [for (final (i, r) in merged.indexed) (i, r)];
  indexed.sort((a, b) {
    final byScore = b.$2.logProb.compareTo(a.$2.logProb);
    return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

double _assignmentLogProb(List<int> labels, List<LineOptions> options) {
  var total = 0.0;
  for (final (index, label) in labels.indexed) {
    total += options[index].logProbs[label]!;
  }
  return total;
}

Hypothesis? _hypothesis(
  List<PricedLine> lines,
  List<List<double>> probas,
  Reference reference,
  Constraints structure,
  double minProb, {
  bool argmaxOnly = false,
  Map<int, int> alternatives = const {},
}) {
  final options = lineOptions(
    lines,
    probas,
    reference.cutoffRank,
    forcedIgnore: structure.forcedIgnore,
    referenceRank: reference.lineRank,
    argmaxOnly: argmaxOnly,
    alternatives: alternatives,
    softIgnore: structure.softIgnore,
  );
  final assignment = bestAssignmentDetail(
    options,
    reference.cents,
    minProb: minProb,
  );
  if (assignment == null) return null;
  final labels = [...assignment.labels];
  final logProb = _assignmentLogProb(labels, options) + reference.logProb;
  if (reference.lineRank case final lineRank?) {
    labels[lineRank] = reference.role;
  }
  return Hypothesis(
    referenceCents: reference.cents,
    referenceRole: reference.role,
    labels: labels,
    logProb: logProb,
    sources: reference.sources,
    cents: assignment.cents,
  );
}

Hypothesis? _bestTotalHypothesis(
  List<PricedLine> lines,
  List<List<double>> probas,
  List<Reference> references,
  Constraints structure,
  double minProb,
  Map<int, int> alternatives,
) {
  Hypothesis? best;
  for (final reference in references) {
    final hypothesis = _hypothesis(
      lines,
      probas,
      reference,
      structure,
      minProb,
      alternatives: alternatives,
    );
    if (hypothesis != null &&
        (best == null || hypothesis.logProb > best.logProb)) {
      best = hypothesis;
    }
  }
  return best;
}

Hypothesis? _paymentHypothesis(
  List<PricedLine> lines,
  List<List<double>> probas,
  Constraints structure,
  int maxReferences,
  double minReferenceProb,
) {
  final ranks = List<int>.generate(probas.length, (i) => i)
    ..sort((a, b) {
      final byProb = probas[b][labelPayment].compareTo(probas[a][labelPayment]);
      return byProb != 0 ? byProb : a.compareTo(b);
    });
  final candidates = [
    for (final rank in ranks)
      if (probas[rank][labelPayment] >= minReferenceProb &&
          !structure.forcedIgnore.contains(rank) &&
          lines[rank].price > 0)
        rank,
  ].take(maxReferences);
  Hypothesis? best;
  for (final rank in candidates) {
    final reference = Reference(
      cents: _toCents(lines[rank].price),
      cutoffRank: rank,
      role: labelPayment,
      logProb: math.log(probas[rank][labelPayment]),
      sources: const [EvidenceSource.classifier],
      lineRank: rank,
    );
    final hypothesis = _hypothesis(
      lines,
      probas,
      reference,
      structure,
      0.0,
      argmaxOnly: true,
    );
    if (hypothesis != null &&
        (best == null || hypothesis.logProb > best.logProb)) {
      best = hypothesis;
    }
  }
  return best;
}

bool _noItemCandidate(List<LineOptions> options, double minProb) {
  final floor = minProb > 0 ? math.log(minProb) : double.negativeInfinity;
  return options.every(
    (option) => (option.logProbs[labelItem] ?? double.negativeInfinity) < floor,
  );
}

Hypothesis? _singleItemHypothesis(
  List<PricedLine> lines,
  List<List<double>> probas,
  List<Reference> references,
  Constraints structure,
  double minProb,
  int? printedCount,
) {
  if (printedCount != null && printedCount != 1) return null;
  for (final reference in references) {
    if (reference.sources.length < singleItemMinSources) continue;
    if (!reference.sources.any(arithmeticSources.contains)) continue;
    final options = lineOptions(
      lines,
      probas,
      reference.cutoffRank,
      forcedIgnore: structure.forcedIgnore,
      referenceRank: reference.lineRank,
      softIgnore: structure.softIgnore,
    );
    if (!_noItemCandidate(options, minProb)) continue;
    final labels = List<int>.filled(lines.length, labelIgnore);
    if (reference.lineRank case final lineRank?) {
      labels[lineRank] = labelTotal;
    }
    return Hypothesis(
      referenceCents: reference.cents,
      referenceRole: labelTotal,
      labels: labels,
      logProb: reference.logProb,
      sources: reference.sources,
      singleItem: true,
    );
  }
  return null;
}

List<Reference> references(
  List<PricedLine> lines,
  List<List<double>> probas,
  Constraints structure, {
  double minReferenceProb = defaultMinReferenceProb,
}) => mergeReferences([
  ..._classifierReferences(lines, probas, structure, minReferenceProb),
  ..._evidenceReferences(probas, structure),
]);

Hypothesis? decodeConstrained(
  List<PricedLine> lines,
  List<List<double>> probas, {
  double minProb = defaultMinProb,
  int maxReferences = defaultMaxReferences,
  double minReferenceProb = defaultMinReferenceProb,
  int? printedCount,
  Map<int, int> alternatives = const {},
}) {
  final structure = constraints(lines);
  final candidates = references(
    lines,
    probas,
    structure,
    minReferenceProb: minReferenceProb,
  ).take(maxReferences).toList();
  final total = _bestTotalHypothesis(
    lines,
    probas,
    candidates,
    structure,
    minProb,
    alternatives,
  );
  if (total != null) return total;
  final payment = _paymentHypothesis(
    lines,
    probas,
    structure,
    maxReferences,
    minReferenceProb,
  );
  if (payment != null) return payment;
  return _singleItemHypothesis(
    lines,
    probas,
    candidates,
    structure,
    minProb,
    printedCount,
  );
}

Map<int, String?> _pendingLabels(
  List<PhysicalLine> merged,
  List<PricedLine> lines,
) {
  final pricedIndexes = {for (final priced in lines) priced.index};
  final pendingByIndex = <int, String?>{};
  String? pending;
  for (final (index, line) in merged.indexed) {
    pendingByIndex[index] = pending;
    pending = pricedIndexes.contains(index) ? null : plausibleLabel(line.text);
  }
  return pendingByIndex;
}

String? _storeOf(List<PhysicalLine> merged) =>
    merged.isEmpty ? null : merged.first.text;

ExtractedReceipt? receiptFromLabels(
  List<PhysicalLine> merged,
  List<PricedLine> lines,
  List<int> labels, {
  double? referenceTotal,
}) {
  final pendingByIndex = _pendingLabels(merged, lines);
  final labelColumn = labelColumnLeft(merged);
  final items = <ExtractedItem>[];
  double? total;
  double? payment;
  for (final (rank, priced) in lines.indexed) {
    var label = labels[rank];
    final price = roundCents(priced.price);
    if (label == labelItem && price < 0) label = labelDiscount;
    if (label == labelItem) {
      final zone = labelZone(priced.line, labelColumn).trim();
      final name =
          plausibleLabel(zone) ?? pendingByIndex[priced.index] ?? zone;
      items.add(
        ExtractedItem(
          name: cleanName(name),
          amount: price,
          discount: 0.0,
          lineIndex: priced.index,
        ),
      );
    } else if (label == labelDiscount && items.isNotEmpty) {
      items.last.discount = roundCents(items.last.discount + price.abs());
    } else if (label == labelTotal) {
      total = price;
    } else if (label == labelPayment && payment == null) {
      payment = price;
    }
  }
  if (items.isEmpty) return null;
  return ExtractedReceipt(
    store: _storeOf(merged),
    date: findDate(merged),
    total: total ?? referenceTotal,
    subtotal: null,
    payment: payment,
    items: items,
  );
}

ExtractedReceipt singleItemReceipt(List<PhysicalLine> merged, double total) {
  final store = _storeOf(merged);
  return ExtractedReceipt(
    store: store,
    date: findDate(merged),
    total: total,
    subtotal: null,
    payment: null,
    items: [
      ExtractedItem(name: cleanName(store ?? ''), amount: total, discount: 0.0),
    ],
  );
}

Map<int, int> rankAlternatives(
  List<PricedLine> lines,
  Map<int, int> alternatives,
) => {
  for (final (rank, priced) in lines.indexed) rank: ?alternatives[priced.index],
};

List<PricedLine> withChosenAmounts(
  List<PricedLine> lines,
  List<int> labels,
  List<int> cents,
) => [
  for (final (rank, priced) in lines.indexed)
    if ((labels[rank] == labelItem || labels[rank] == labelDiscount) &&
        cents[rank] != _toCents(priced.price))
      PricedLine(
        index: priced.index,
        line: priced.line,
        price: cents[rank] / 100,
        word: priced.word,
      )
    else
      priced,
];
