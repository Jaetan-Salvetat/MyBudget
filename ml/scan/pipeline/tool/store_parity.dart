import 'dart:convert';
import 'dart:io';

import 'package:receipt_pipeline/receipt_pipeline.dart';

void main(List<String> args) {
  final classifier = StoreClassifier.fromJson(
    jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>,
  );
  final tickets = jsonDecode(File(args[1]).readAsStringSync()) as List;
  stdout.writeln(
    jsonEncode([
      for (final ticket in tickets)
        classifier.predict([
          for (final text in ticket as List)
            PhysicalLine(
              words: [
                for (final token in (text as String).split(' '))
                  Word(
                    text: token,
                    left: 0,
                    top: 0,
                    right: 1,
                    bottom: 1,
                    confidence: null,
                  ),
              ],
            ),
        ]),
    ]),
  );
}
