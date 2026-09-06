import 'dart:convert';
import 'dart:io';

import 'package:receipt_pipeline/receipt_pipeline.dart';

void main(List<String> args) {
  final gazetteer = Gazetteer(
    (jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as String),
    ),
  );
  final lines = jsonDecode(File(args[1]).readAsStringSync()) as List;
  stdout.writeln(
    jsonEncode([for (final l in lines) gazetteer.match(l as String)]),
  );
}
