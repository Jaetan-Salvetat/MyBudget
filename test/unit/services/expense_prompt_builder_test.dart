import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/expense_prompt_builder.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';

void main() {
  group('ExpensePromptBuilder', () {
    late List<CategoryModel> categories;

    setUp(() {
      categories = [
        CategoryModel.create(name: 'Alimentation', icon: 'restaurant', color: 0xFFFF5722)
          ..id = 1,
        CategoryModel.create(name: 'Transport', icon: 'directions_car', color: 0xFF2196F3)
          ..id = 2,
      ];
    });

    group('buildParse', () {
      test('includes category names and IDs', () {
        final prompt = ExpensePromptBuilder.buildParse(categories, []);

        expect(prompt, contains('Alimentation'));
        expect(prompt, contains('Transport'));
        expect(prompt, contains('"id":1'));
        expect(prompt, contains('"id":2'));
      });

      test('does not include icon or color in categories', () {
        final prompt = ExpensePromptBuilder.buildParse(categories, []);

        expect(prompt, isNot(contains('"icon"')));
        expect(prompt, isNot(contains('"color"')));
      });

      test('includes rules about broad categories', () {
        final prompt = ExpensePromptBuilder.buildParse(categories, []);

        expect(prompt, contains('broad'));
        expect(prompt, contains('Abonnements'));
        expect(prompt, contains('Netflix'));
      });

      test('includes frequency rules', () {
        final prompt = ExpensePromptBuilder.buildParse(categories, []);

        expect(prompt, contains('Ponctuel'));
        expect(prompt, contains('Mensuel'));
        expect(prompt, contains('Annuel'));
      });

      test('includes few-shot examples', () {
        final prompt = ExpensePromptBuilder.buildParse(categories, []);

        expect(prompt, contains('Examples'));
        expect(prompt, contains('"Café"'));
        expect(prompt, contains('"Salle de sport"'));
        expect(prompt, contains('"Netflix"'));
      });

      test('uses actual Alimentation ID in example', () {
        final prompt = ExpensePromptBuilder.buildParse(categories, []);

        expect(prompt, contains('"categoryId":1'));
      });

      test('includes recurring expenses when provided', () {
        final recurring = [
          ExpenseModel.create(
            name: 'Spotify',
            amount: 9.99,
            categoryId: 1,
            startDate: DateTime.now(),
            frequency: 'Mensuel',
            accountId: 1,
          ),
        ];

        final prompt = ExpensePromptBuilder.buildParse(categories, recurring);

        expect(prompt, contains('Spotify'));
        expect(prompt, contains('recurring'));
      });

      test('omits recurring section when list is empty', () {
        final prompt = ExpensePromptBuilder.buildParse(categories, []);

        expect(prompt, isNot(contains('recurring')));
      });

      test('handles empty categories list', () {
        final prompt = ExpensePromptBuilder.buildParse([], []);

        expect(prompt, contains('[]'));
      });
    });

    group('buildParseLocal', () {
      test('contains base prompt content', () {
        final prompt = ExpensePromptBuilder.buildParseLocal(categories, []);

        expect(prompt, contains('Alimentation'));
        expect(prompt, contains('Examples'));
      });

      test('appends JSON-only instruction', () {
        final prompt = ExpensePromptBuilder.buildParseLocal(categories, []);

        expect(prompt, contains('IMPORTANT'));
        expect(prompt, contains('ONLY'));
        expect(prompt, contains('JSON'));
      });

      test('schema does not include icon or color fields', () {
        final prompt = ExpensePromptBuilder.buildParseLocal(categories, []);

        expect(prompt, isNot(contains('newCategoryIcon')));
        expect(prompt, isNot(contains('newCategoryColor')));
      });
    });

    group('buildCategorize', () {
      test('includes category name', () {
        final prompt = ExpensePromptBuilder.buildCategorize('Sport');

        expect(prompt, contains('Sport'));
      });

      test('includes available icons', () {
        final prompt = ExpensePromptBuilder.buildCategorize('Sport');

        expect(prompt, contains('restaurant'));
        expect(prompt, contains('fitness_center'));
        expect(prompt, contains('home'));
      });

      test('includes available colors as hex', () {
        final prompt = ExpensePromptBuilder.buildCategorize('Sport');

        expect(prompt, contains('#EF5350'));
        expect(prompt, contains('#42A5F5'));
      });

      test('includes few-shot examples from default categories', () {
        final prompt = ExpensePromptBuilder.buildCategorize('Sport');

        expect(prompt, contains('Alimentation'));
        expect(prompt, contains('"icon":"restaurant"'));
      });

      test('ends with JSON-only instruction', () {
        final prompt = ExpensePromptBuilder.buildCategorize('Sport');

        expect(prompt, contains('ONLY'));
        expect(prompt, contains('{"icon"'));
      });
    });
  });
}
