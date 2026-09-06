import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/data/model/quick_add_draft_model.dart';

void main() {
  group('QuickAddDraft', () {
    test('the empty draft carries nothing', () {
      expect(QuickAddDraft.empty.isEmpty, isTrue);
      expect(QuickAddDraft.empty.isSubmittable, isFalse);
      expect(QuickAddDraft.empty.amount, isNull);
      expect(QuickAddDraft.empty.categorySlug, isNull);
    });

    test('whitespace-only input counts as empty', () {
      expect(const QuickAddDraft(input: '   ').isEmpty, isTrue);
    });

    test('is not submittable while the amount is missing', () {
      const draft = QuickAddDraft(
        input: 'mc do',
        name: 'Mc do',
        categorySlug: 'restauration.fast_food',
      );

      expect(draft.isSubmittable, isFalse);
    });

    test('an amount alone is enough : the category has a fallback', () {
      const draft = QuickAddDraft(input: 'mc do 12', amount: 12.0);

      expect(draft.isSubmittable, isTrue);
      expect(draft.categorySlugOrFallback, QuickAddDraft.uncategorizedSlug);
    });

    test('is not submittable with a zero amount', () {
      const draft = QuickAddDraft(
        input: 'mc do 0',
        amount: 0,
        name: 'Mc do',
        categorySlug: 'restauration.fast_food',
      );

      expect(draft.isSubmittable, isFalse);
    });

    test('a known category is kept over the fallback', () {
      const draft = QuickAddDraft(
        input: 'mc do 12',
        amount: 12.0,
        categorySlug: 'restauration.fast_food',
      );

      expect(draft.categorySlugOrFallback, 'restauration.fast_food');
    });

    test('is submittable once amount and category are known', () {
      const draft = QuickAddDraft(
        input: 'mc do 12',
        amount: 12.0,
        name: 'Mc do',
        categorySlug: 'restauration.fast_food',
      );

      expect(draft.isSubmittable, isTrue);
    });

    test('flags a category the model is unsure about', () {
      const draft = QuickAddDraft(
        input: 'truc 12',
        amount: 12.0,
        categorySlug: 'divers.autre',
        categoryConfidence: 0.3,
      );

      expect(draft.isCategoryUncertain, isTrue);
    });

    test('a confident category is not flagged', () {
      const draft = QuickAddDraft(
        input: 'mc do 12',
        amount: 12.0,
        categorySlug: 'restauration.fast_food',
        categoryConfidence: 0.95,
      );

      expect(draft.isCategoryUncertain, isFalse);
    });

    test('copyWith replaces the category and keeps the rest', () {
      const draft = QuickAddDraft(
        input: 'mc do 12',
        amount: 12.0,
        name: 'Mc do',
        categorySlug: 'restauration.fast_food',
        categoryConfidence: 0.3,
        type: TransactionType.expense,
        frequency: Frequency.oneTime,
      );

      final updated = draft.copyWith(
        categorySlug: 'loisirs.cinema',
        categoryConfidence: 1.0,
      );

      expect(updated.categorySlug, 'loisirs.cinema');
      expect(updated.categoryConfidence, 1.0);
      expect(updated.amount, 12.0);
      expect(updated.name, 'Mc do');
      expect(updated.input, 'mc do 12');
    });

    test('a reading that predates the current input is stale', () {
      const draft = QuickAddDraft(
        input: 'mc do 12 avec Paul',
        analyzedInput: 'mc do 12',
        amount: 12.0,
        categorySlug: 'restauration.fast_food',
      );

      expect(draft.isStale, isTrue);
    });

    test('a reading of the current input is not stale', () {
      const draft = QuickAddDraft(
        input: 'mc do 12',
        analyzedInput: 'mc do 12',
        amount: 12.0,
      );

      expect(draft.isStale, isFalse);
    });

    test('the empty draft has nothing pending', () {
      expect(QuickAddDraft.empty.isStale, isFalse);
    });
  });
}
