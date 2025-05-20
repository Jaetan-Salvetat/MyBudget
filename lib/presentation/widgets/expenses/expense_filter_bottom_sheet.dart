import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';

enum ExpenseSortOption {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
  nameAsc,
  nameDesc,
}

class ExpenseFilterData {
  final List<int> selectedCategoryIds;
  final List<int> selectedAccountIds;
  final List<String> selectedFrequencies;
  final ExpenseSortOption sortOption;

  ExpenseFilterData({
    this.selectedCategoryIds = const [],
    this.selectedAccountIds = const [],
    this.selectedFrequencies = const [],
    this.sortOption = ExpenseSortOption.dateAsc,
  });

  ExpenseFilterData copyWith({
    List<int>? selectedCategoryIds,
    List<int>? selectedAccountIds,
    List<String>? selectedFrequencies,
    ExpenseSortOption? sortOption,
  }) {
    return ExpenseFilterData(
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      selectedAccountIds: selectedAccountIds ?? this.selectedAccountIds,
      selectedFrequencies: selectedFrequencies ?? this.selectedFrequencies,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  bool get isEmpty {
    return selectedCategoryIds.isEmpty &&
        selectedAccountIds.isEmpty &&
        selectedFrequencies.isEmpty;
  }
}

class ExpenseFilterBottomSheet extends StatefulWidget {
  final ExpenseFilterData initialFilterData;
  final Function(ExpenseFilterData) onApply;
  final VoidCallback onCancel;
  final VoidCallback onClear;

  const ExpenseFilterBottomSheet({
    required this.initialFilterData,
    required this.onApply,
    required this.onCancel,
    required this.onClear,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required ExpenseFilterData initialFilterData,
    required Function(ExpenseFilterData) onApply,
    required VoidCallback onCancel,
    required VoidCallback onClear,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Filtrer et trier',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ExpenseFilterBottomSheet(
                          initialFilterData: initialFilterData,
                          onApply: onApply,
                          onCancel: onCancel,
                          onClear: onClear,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AppModalButton(
                            label: 'Quitter',
                            onPressed: onCancel,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppModalButton(
                            label: 'Effacer',
                            isDestructive: true,
                            onPressed: () {
                              onApply(ExpenseFilterData());
                              onClear();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  State<ExpenseFilterBottomSheet> createState() =>
      _ExpenseFilterBottomSheetState();
}

class _ExpenseFilterBottomSheetState extends State<ExpenseFilterBottomSheet> {
  late ExpenseFilterData filterData;

  late List<CategoryModel> availableCategories;
  late List<AccountModel> availableAccounts;
  final List<String> availableFrequencies = ['Mensuel', 'Annuel'];

  final Map<ExpenseSortOption, String> sortOptionLabels = {
    ExpenseSortOption.dateDesc: 'Date du mois (fin du mois)',
    ExpenseSortOption.dateAsc: 'Date du mois (début du mois)',
    ExpenseSortOption.amountDesc: 'Montant (décroissant)',
    ExpenseSortOption.amountAsc: 'Montant (croissant)',
    ExpenseSortOption.nameAsc: 'Nom (A-Z)',
    ExpenseSortOption.nameDesc: 'Nom (Z-A)',
  };

  @override
  void initState() {
    super.initState();
    filterData = widget.initialFilterData;

    final categoryController = Get.find<CategoryController>();
    availableCategories = categoryController.categories;

    final accountController = Get.find<AccountController>();
    availableAccounts = accountController.accounts;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSortSection(),
        const SizedBox(height: 24),
        _buildCategoryFilterSection(),
        const SizedBox(height: 24),
        _buildAccountFilterSection(),
        const SizedBox(height: 24),
        _buildFrequencyFilterSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trier par',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children:
                sortOptionLabels.entries.map((entry) {
                  return RadioListTile<ExpenseSortOption>(
                    title: Text(entry.value),
                    value: entry.key,
                    groupValue: filterData.sortOption,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          filterData = filterData.copyWith(
                            sortOption: value,
                          );
                          widget.onApply(filterData);
                        });
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableCategories.map((category) {
                  final isSelected = filterData.selectedCategoryIds.contains(
                    category.id,
                  );
                  return FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        final updatedCategoryIds = List<int>.from(
                          filterData.selectedCategoryIds,
                        );
                        if (selected) {
                          updatedCategoryIds.add(category.id);
                        } else {
                          updatedCategoryIds.remove(category.id);
                        }
                        filterData = filterData.copyWith(
                          selectedCategoryIds: updatedCategoryIds,
                        );
                        widget.onApply(filterData);
                      });
                    },
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comptes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableAccounts.map((account) {
                  final isSelected = filterData.selectedAccountIds.contains(
                    account.id,
                  );
                  return FilterChip(
                    label: Text(account.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        final updatedAccountIds = List<int>.from(
                          filterData.selectedAccountIds,
                        );
                        if (selected) {
                          updatedAccountIds.add(account.id);
                        } else {
                          updatedAccountIds.remove(account.id);
                        }
                        filterData = filterData.copyWith(
                          selectedAccountIds: updatedAccountIds,
                        );
                        widget.onApply(filterData);
                      });
                    },
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fréquence',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableFrequencies.map((frequency) {
                  final isSelected = filterData.selectedFrequencies.contains(
                    frequency,
                  );
                  return FilterChip(
                    label: Text(frequency),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        final updatedFrequencies = List<String>.from(
                          filterData.selectedFrequencies,
                        );
                        if (selected) {
                          updatedFrequencies.add(frequency);
                        } else {
                          updatedFrequencies.remove(frequency);
                        }
                        filterData = filterData.copyWith(
                          selectedFrequencies: updatedFrequencies,
                        );
                        widget.onApply(filterData);
                      });
                    },
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

extension ExpenseFilterExtension on List<ExpenseModel> {
  List<ExpenseModel> applyFilter(ExpenseFilterData filterData) {
    List<ExpenseModel> filteredList = [...this];

    if (filterData.selectedCategoryIds.isNotEmpty) {
      filteredList =
          filteredList
              .where(
                (expense) =>
                    filterData.selectedCategoryIds.contains(expense.categoryId),
              )
              .toList();
    }

    if (filterData.selectedAccountIds.isNotEmpty) {
      filteredList =
          filteredList
              .where(
                (expense) =>
                    filterData.selectedAccountIds.contains(expense.accountId),
              )
              .toList();
    }

    if (filterData.selectedFrequencies.isNotEmpty) {
      filteredList =
          filteredList
              .where(
                (expense) =>
                    filterData.selectedFrequencies.contains(expense.frequency),
              )
              .toList();
    }

    switch (filterData.sortOption) {
      case ExpenseSortOption.dateDesc:
        filteredList.sort((a, b) => b.date.day.compareTo(a.date.day));
        break;
      case ExpenseSortOption.dateAsc:
        filteredList.sort((a, b) => a.date.day.compareTo(b.date.day));
        break;
      case ExpenseSortOption.amountDesc:
        filteredList.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case ExpenseSortOption.amountAsc:
        filteredList.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case ExpenseSortOption.nameAsc:
        filteredList.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ExpenseSortOption.nameDesc:
        filteredList.sort((a, b) => b.name.compareTo(a.name));
        break;
    }

    return filteredList;
  }
}
