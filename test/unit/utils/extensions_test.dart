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
  });
}
