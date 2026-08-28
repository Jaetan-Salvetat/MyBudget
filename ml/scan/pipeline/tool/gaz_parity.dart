import 'dart:convert';
import 'dart:io';
import 'package:receipt_pipeline/receipt_pipeline.dart';

/// Rejoue le répertoire Python sur les mêmes lignes et rend son verdict.
void main(List<String> args) {
  final entries = (jsonDecode(File(args[0]).readAsStringSync()) as Map)
      .map((k, v) => MapEntry(k as String, v as String));
  final gazetteer = Gazetteer(entries);
  final lines = jsonDecode(File(args[1]).readAsStringSync()) as List;
  stdout.writeln(jsonEncode([for (final l in lines) gazetteer.match(l as String)]));
}
