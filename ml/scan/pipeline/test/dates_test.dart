import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

PhysicalLine line(String text) => PhysicalLine(
  words: [
    for (final token in text.split(' '))
      Word(
        text: token,
        left: 0,
        top: 0,
        right: 10,
        bottom: 10,
        confidence: null,
      ),
  ],
);

String? dateOf(String text) => findDate([line(text)]);

void main() {
  group('date reading', () {
    test('four digit year', () {
      expect(dateOf('Le 24/02/2017 a 10:49'), '2017-02-24');
      expect(dateOf('24.02.2017'), '2017-02-24');
      expect(dateOf('0001 004 000035 24/02/2017 10:49:08'), '2017-02-24');
    });

    test('two digit year', () {
      expect(dateOf('18/12/16'), '2016-12-18');
      expect(dateOf('Ticket du 18/12/16 a 14:02'), '2016-12-18');
      expect(dateOf('13/03/17 20:30'), '2017-03-13');
    });

    test('a glued time never becomes the year', () {
      expect(dateOf('01/07/26 19:04:07 0004431 Pos 101'), '2026-07-01');
      expect(dateOf('13/03/1720:30:12'), '2017-03-13');
    });

    test('digits split by the ocr are reglued', () {
      expect(dateOf('24/02/202 6'), '2026-02-24');
    });

    test('a literal month', () {
      expect(dateOf('Le 02 juillet 2020 09:32'), '2020-07-02');
      expect(dateOf('1er août 2024'), '2024-08-01');
    });

    test('the time before the date does not lend its digits', () {
      expect(dateOf('17:25:01 7/02/2025'), '2025-02-07');
      expect(dateOf('19:07:33 1/08/2024'), '2024-08-01');
      expect(dateOf('13:29:21 1/11/2025'), '2025-11-01');
    });

    test('a short year followed by a dash stays a year', () {
      expect(dateOf('17/09/24 - 12:47 940 94 2308'), '2024-09-17');
      expect(dateOf('06/07/24 - 11:23 980 98 5835'), '2024-07-06');
    });

    test('a slashed register code is not a date', () {
      expect(dateOf('3883 408264/07/12/02 17.01.25 11:03:20'), '2025-01-17');
      expect(dateOf('3979 645298/04/23/01 12.03.26 12:31:39'), '2026-03-12');
    });

    test('a month damaged by the ocr stays readable', () {
      expect(dateOf('Le 23 jurilet 2025 à 21:52:52'), '2025-07-23');
      expect(dateOf('Caisse 011-0102 02 jufllet 2020 09:32'), '2020-07-02');
    });

    test('a spaced date with a full year', () {
      expect(dateOf('samedi 31 5 2025 16:20'), '2025-05-31');
    });

    test('spaced digits without a full year are not a date', () {
      expect(dateOf('940 94 2308 12 47'), isNull);
    });

    test('a masked phone number is not a date', () {
      expect(dateOf('Tel 01.43.94.91.64'), isNull);
    });
  });
}
