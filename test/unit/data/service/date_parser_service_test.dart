import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/data/service/quick_add/date_parser_service.dart';

void main() {
  final today = DateTime(2026, 8, 20);

  DateParseResult? parse(String input) =>
      DateParserService.parse(input, today: today);

  group('DateParserService relative days', () {
    test('reads yesterday', () {
      expect(parse('café hier')?.date, DateTime(2026, 8, 19));
    });

    test('reads the day before yesterday, hyphenated or not', () {
      expect(parse('café avant-hier')?.date, DateTime(2026, 8, 18));
      expect(parse('café avant hier')?.date, DateTime(2026, 8, 18));
    });

    test('reads today', () {
      expect(parse('café aujourd\'hui')?.date, today);
      expect(parse('café aujourdhui')?.date, today);
    });

    test('reads tomorrow', () {
      expect(parse('loyer demain')?.date, DateTime(2026, 8, 21));
    });

    test('reads a count of days, weeks or months back', () {
      expect(parse('café il y a 3 jours')?.date, DateTime(2026, 8, 17));
      expect(parse('café il y a 2 semaines')?.date, DateTime(2026, 8, 6));
      expect(parse('café il y a 1 mois')?.date, DateTime(2026, 7, 20));
    });
  });

  group('DateParserService weekdays', () {
    test('resolves to the most recent one that has passed', () {
      expect(parse('resto samedi')?.date, DateTime(2026, 8, 15));
      expect(parse('resto lundi')?.date, DateTime(2026, 8, 17));
    });

    test('today counts as the most recent one', () {
      expect(parse('resto jeudi')?.date, today);
    });

    test('"dernier" always steps back a full week', () {
      expect(parse('resto jeudi dernier')?.date, DateTime(2026, 8, 13));
      expect(parse('resto samedi dernier')?.date, DateTime(2026, 8, 15));
    });

    test('reads a weekday whatever the case', () {
      expect(parse('resto Mercredi')?.date, DateTime(2026, 8, 19));
    });
  });

  group('DateParserService explicit dates', () {
    test('reads a day of the month', () {
      expect(parse('essence le 12')?.date, DateTime(2026, 8, 12));
    });

    test('a day still to come belongs to the month before', () {
      expect(parse('essence le 25')?.date, DateTime(2026, 7, 25));
    });

    test('reads a slashed day and month', () {
      expect(parse('essence 12/03')?.date, DateTime(2026, 3, 12));
      expect(parse('essence le 12/03')?.date, DateTime(2026, 3, 12));
    });

    test('a slashed date still to come belongs to the year before', () {
      expect(parse('essence 25/12')?.date, DateTime(2025, 12, 25));
    });

    test('reads an explicit year, two or four digits', () {
      expect(parse('essence 12/03/2024')?.date, DateTime(2024, 3, 12));
      expect(parse('essence 12/03/24')?.date, DateTime(2024, 3, 12));
    });

    test('reads a named month', () {
      expect(parse('essence le 12 mars')?.date, DateTime(2026, 3, 12));
      expect(parse('essence 3 février')?.date, DateTime(2026, 2, 3));
      expect(parse('essence 1er août')?.date, DateTime(2026, 8, 1));
    });

    test('rejects an impossible day', () {
      expect(parse('essence 32/03'), isNull);
      expect(parse('essence le 45'), isNull);
    });
  });

  group('DateParserService leaves the rest alone', () {
    test('strips only what it read', () {
      expect(parse('café 3,50 hier')?.remaining, 'café 3,50');
      expect(parse('essence 60 le 12')?.remaining, 'essence 60');
      expect(parse('resto samedi dernier 25')?.remaining, 'resto 25');
    });

    test('a bare number is never a date', () {
      expect(parse('café 12'), isNull);
      expect(parse('netflix 13,99'), isNull);
      expect(parse('salaire 2500'), isNull);
    });

    test('a decimal amount is never a date', () {
      expect(parse('mc do 12.50'), isNull);
    });

    test('reads nothing out of a text that carries no date', () {
      expect(parse('courses carrefour'), isNull);
      expect(parse(''), isNull);
    });

    test('reads the first date in the text and stops there', () {
      expect(parse('resto hier avec le 12')?.date, DateTime(2026, 8, 19));
      expect(parse('resto le 12 puis hier')?.date, DateTime(2026, 8, 12));
    });
  });
}
