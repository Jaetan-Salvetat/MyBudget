import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mybudget/core/services/scan/receipt_line_recognizer.dart';

TextElement _element(String text, Rect box) {
  return TextElement(
    text: text,
    boundingBox: box,
    cornerPoints: const [],
    recognizedLanguages: const [],
    confidence: 0.9,
    angle: null,
    symbols: const [],
  );
}

TextLine _line(List<TextElement> elements, {double? angle}) {
  return TextLine(
    text: elements.map((element) => element.text).join(' '),
    elements: elements,
    boundingBox: elements.first.boundingBox,
    recognizedLanguages: const [],
    cornerPoints: const [],
    confidence: 0.9,
    angle: angle,
  );
}

RecognizedText _recognized(List<TextLine> lines) {
  return RecognizedText(
    text: lines.map((line) => line.text).join('\n'),
    blocks: [
      TextBlock(
        text: lines.map((line) => line.text).join('\n'),
        lines: lines,
        boundingBox: lines.first.boundingBox,
        recognizedLanguages: const [],
        cornerPoints: const [],
      ),
    ],
  );
}

void main() {
  group('lecture ML Kit', () {
    test('chaque élément devient un mot du pipeline', () {
      final recognized = _recognized([
        _line([
          _element('PAIN', const Rect.fromLTRB(0, 0, 60, 30)),
          _element('2,00', const Rect.fromLTRB(200, 0, 260, 30)),
        ]),
      ]);

      final words = recognizedWords(recognized);

      expect([for (final word in words) word.text], ['PAIN', '2,00']);
      expect(words.last.left, 200);
      expect(words.last.confidence, 0.9);
    });

    test('seuls les angles connus servent au redressement', () {
      final recognized = _recognized([
        _line([
          _element('PAIN', const Rect.fromLTRB(0, 0, 60, 30)),
        ], angle: 2.0),
        _line([_element('LAIT', const Rect.fromLTRB(0, 40, 60, 70))]),
      ]);

      expect(recognizedAngles(recognized), [2.0]);
    });

    test('les mots d\'une même hauteur forment une ligne physique', () {
      final recognized = _recognized([
        _line([
          _element('PAIN', const Rect.fromLTRB(0, 0, 60, 30)),
          _element('2,00', const Rect.fromLTRB(200, 0, 260, 30)),
        ]),
        _line([
          _element('LAIT', const Rect.fromLTRB(0, 40, 60, 70)),
          _element('3,00', const Rect.fromLTRB(200, 40, 260, 70)),
        ]),
      ]);

      final lines = recognizedLines(recognized);

      expect(lines.length, 2);
      expect(lines.first.text, 'PAIN 2,00');
      expect(lines.last.text, 'LAIT 3,00');
    });
  });
}
