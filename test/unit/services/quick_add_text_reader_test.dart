import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/quick_add/quick_add_text_reader.dart';

void main() {
  final today = DateTime(2026, 8, 20);

  QuickAddTextFacts read(String input) =>
      QuickAddTextReader.read(input, today: today);

  test('reads the date before the amount, so neither steals the other', () {
    final facts = read('essence 60 le 12');

    expect(facts.date, DateTime(2026, 8, 12));
    expect(facts.amount, 60.0);
    expect(facts.remaining, 'essence');
  });

  test('falls back to today when the text carries no date', () {
    final facts = read('café 3,50');

    expect(facts.date, today);
    expect(facts.hasWrittenDate, isFalse);
    expect(facts.amount, 3.5);
    expect(facts.remaining, 'café');
  });

  test('flags a date the user actually wrote', () {
    expect(read('café 3,50 hier').hasWrittenDate, isTrue);
  });

  test('leaves the amount null while none is typed', () {
    final facts = read('courses carrefour hier');

    expect(facts.amount, isNull);
    expect(facts.remaining, 'courses carrefour');
  });

  test('the model still gets something when the entry is only an amount', () {
    final facts = read('25');

    expect(facts.amount, 25.0);
    expect(facts.remaining, isEmpty);
    expect(facts.modelText, '25');
  });

  test('the model reads what is left once date and amount are out', () {
    expect(read('essence 60 le 12').modelText, 'essence');
  });

  test('a bare number stays an amount', () {
    final facts = read('café 12');

    expect(facts.date, today);
    expect(facts.amount, 12.0);
    expect(facts.remaining, 'café');
  });
}
