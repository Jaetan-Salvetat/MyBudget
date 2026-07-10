import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_result_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_provider.g.dart';

@riverpod
class QuickAddNotifier extends _$QuickAddNotifier {
  static const Map<String, String> _diacritics = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };

  @override
  AsyncValue<QuickAddResultModel?> build() {
    return const AsyncData(null);
  }

  Future<void> parse(String input) async {
    state = const AsyncLoading();

    try {
      final classifier = await ref.read(quickAddClassifierProvider.future);
      final classification = await classifier.classify(input);
      final categories = await ref.read(categoryProvider.future);
      state = AsyncData(_toResult(classification, categories));
    } on QuickAddException catch (e, st) {
      state = AsyncError(e, st);
    } catch (e, st) {
      state = AsyncError(
        QuickAddClassificationException(message: 'Analyse impossible : $e'),
        st,
      );
    }
  }

  Future<void> confirm(int accountId) async {
    final result = state.value;
    if (result == null) return;

    try {
      if (result.type == TransactionType.income) {
        final revenue = RevenueModel.create(
          name: result.name,
          amount: result.amount,
          startDate: DateTime.now(),
          frequency: result.frequency,
          accountId: accountId,
        );
        await ref.read(revenueProvider.notifier).addRevenue(revenue);
      } else {
        final expense = ExpenseModel.create(
          name: result.name,
          amount: result.amount,
          categoryId: _ensureCategory(result),
          startDate: DateTime.now(),
          frequency: result.frequency,
          accountId: accountId,
        );
        await ref.read(expenseProvider.notifier).addExpense(expense);
      }
      state = const AsyncData(null);
    } catch (e) {
      rethrow;
    }
  }

  void reset() {
    state = const AsyncData(null);
  }

  QuickAddResultModel _toResult(
    QuickAddClassification classification,
    List<CategoryModel> categories,
  ) {
    if (classification.type == TransactionType.income) {
      return QuickAddResultModel(
        type: TransactionType.income,
        name: classification.name,
        amount: classification.amount,
        frequency: classification.frequency.label,
      );
    }

    final existing =
        _findExistingCategory(categories, classification.group.label);
    if (existing != null) {
      return QuickAddResultModel(
        type: TransactionType.expense,
        name: classification.name,
        amount: classification.amount,
        frequency: classification.frequency.label,
        categoryId: existing.id,
      );
    }

    return QuickAddResultModel(
      type: TransactionType.expense,
      name: classification.name,
      amount: classification.amount,
      frequency: classification.frequency.label,
      newCategory: classification.group.label,
      newCategoryIcon: classification.group.icon,
      newCategoryColor: classification.group.color,
    );
  }

  CategoryModel? _findExistingCategory(
    List<CategoryModel> categories,
    String groupLabel,
  ) {
    final target = _normalize(groupLabel);

    for (final category in categories) {
      if (_normalize(category.name) == target) return category;
    }
    return null;
  }

  int _ensureCategory(QuickAddResultModel result) {
    final existingId = result.categoryId;
    if (existingId != null) return existingId;

    final name = result.newCategory;
    if (name == null) {
      throw const QuickAddClassificationException(
        message: 'Résultat sans catégorie',
      );
    }

    final category = CategoryModel.create(
      name: name,
      icon: result.newCategoryIcon ?? CategoryDefaults.defaultIcon,
      color: result.newCategoryColor ?? CategoryDefaults.defaultColor,
    );
    final id = ref.read(categoryRepositoryProvider).add(category);
    ref.invalidate(categoryProvider);
    return id;
  }

  String _normalize(String value) {
    var result = value.toLowerCase().trim();
    for (final entry in _diacritics.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}
