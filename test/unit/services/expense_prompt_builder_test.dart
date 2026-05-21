import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/expense_prompt_builder.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';

void main() {
  group('ExpensePromptBuilder', () {
    late List<CategoryModel> categories;

    setUp(() {
      categories = [
        CategoryModel.create(name: 'Alimentation', icon: 'restaurant', color: 0xFFFF5722),
        CategoryModel.create(name: 'Transport', icon: 'directions_car', color: 0xFF2196F3),
      ];
    });

    group('build', () {
      test('includes category names in prompt', () {
        final prompt = ExpensePromptBuilder.build(categories, []);

        expect(prompt, contains('Alimentation'));
        expect(prompt, contains('Transport'));
      });

      test('includes category icons in prompt', () {
        final prompt = ExpensePromptBuilder.build(categories, []);

        expect(prompt, contains('restaurant'));
        expect(prompt, contains('directions_car'));
      });

      test('includes category IDs in prompt', () {
        final prompt = ExpensePromptBuilder.build(categories, []);

        expect(prompt, contains('"id": 0'));
      });

      test('includes rules section', () {
        final prompt = ExpensePromptBuilder.build(categories, []);

        expect(prompt, contains('Règles'));
        expect(prompt, contains('categoryId'));
        expect(prompt, contains('newCategory'));
        expect(prompt, contains('Ponctuel'));
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

        final prompt = ExpensePromptBuilder.build(categories, recurring);

        expect(prompt, contains('Spotify'));
        expect(prompt, contains('Mensuel'));
        expect(prompt, contains('récurrentes'));
      });

      test('omits recurring section when list is empty', () {
        final prompt = ExpensePromptBuilder.build(categories, []);

        expect(prompt, isNot(contains('récurrentes')));
      });

      test('handles empty categories list', () {
        final prompt = ExpensePromptBuilder.build([], []);

        expect(prompt, contains('Catégories existantes : []'));
      });
    });

    group('buildForLocalModel', () {
      test('contains base prompt content', () {
        final prompt = ExpensePromptBuilder.buildForLocalModel(categories, []);

        expect(prompt, contains('Alimentation'));
        expect(prompt, contains('Règles'));
      });

      test('appends JSON-only instruction', () {
        final prompt = ExpensePromptBuilder.buildForLocalModel(categories, []);

        expect(prompt, contains('UNIQUEMENT'));
        expect(prompt, contains('JSON valide'));
        expect(prompt, contains('"name": string'));
        expect(prompt, contains('"amount": number'));
        expect(prompt, contains('Aucun texte en dehors du JSON'));
      });

      test('includes all frequency enum values', () {
        final prompt = ExpensePromptBuilder.buildForLocalModel(categories, []);

        expect(prompt, contains('"Ponctuel"'));
        expect(prompt, contains('"Mensuel"'));
        expect(prompt, contains('"Annuel"'));
      });
    });
  });
}
