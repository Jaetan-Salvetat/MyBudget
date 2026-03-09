import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/utils/extensions.dart';

void main() {
  group('DateExtension', () {
    test('toFormattedString should return DD/MM/YYYY format', () {
      final date = DateTime(2023, 1, 5);
      expect(date.toFormattedString(), '05/01/2023');
    });

    test('toFormattedString should pad single digits', () {
      final date = DateTime(2023, 11, 15);
      expect(date.toFormattedString(), '15/11/2023');
    });

    test('toFormattedString pads single-digit day and month correctly', () {
      final date = DateTime(2025, 3, 1);
      expect(date.toFormattedString(), '01/03/2025');
    });

    test('toFormattedString handles February 29 in a leap year', () {
      final date = DateTime(2024, 2, 29);
      expect(date.toFormattedString(), '29/02/2024');
    });

    test('toFormattedString handles December 31', () {
      final date = DateTime(2023, 12, 31);
      expect(date.toFormattedString(), '31/12/2023');
    });
  });
}
