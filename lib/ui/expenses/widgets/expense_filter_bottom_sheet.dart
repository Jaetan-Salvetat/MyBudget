import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/expense_filter_data.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/account_model.dart';

class ExpenseFilterBottomSheet extends StatefulWidget {
  final ExpenseFilterData initialFilterData;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final Function(ExpenseFilterData) onApply;
  final VoidCallback onClear;
  final VoidCallback onCancel;

  const ExpenseFilterBottomSheet({
    required this.initialFilterData,
    required this.categories,
    required this.accounts,
    required this.onApply,
    required this.onClear,
    required this.onCancel,
    super.key,
  });

  static void show({
    required BuildContext context,
    required ExpenseFilterData initialFilterData,
    required List<CategoryModel> categories,
    required List<AccountModel> accounts,
    required Function(ExpenseFilterData) onApply,
    required VoidCallback onClear,
    required VoidCallback onCancel,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Filtrer les dépenses',
      child: ExpenseFilterBottomSheet(
        initialFilterData: initialFilterData,
        categories: categories,
        accounts: accounts,
        onApply: onApply,
        onClear: onClear,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<ExpenseFilterBottomSheet> createState() =>
      _ExpenseFilterBottomSheetState();
}

class _ExpenseFilterBottomSheetState extends State<ExpenseFilterBottomSheet> {
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  List<int> _selectedCategoryIds = [];
  List<int> _selectedAccountIds = [];
  List<String> _selectedFrequencies = [];
  double _startDay = 1;
  double _endDay = 31;

  @override
  void initState() {
    super.initState();
    _minAmountController = TextEditingController(
      text: widget.initialFilterData.minAmount?.toString() ?? '',
    );
    _maxAmountController = TextEditingController(
      text: widget.initialFilterData.maxAmount?.toString() ?? '',
    );
    _selectedCategoryIds = List.from(widget.initialFilterData.categoryIds);
    _selectedAccountIds = List.from(widget.initialFilterData.accountIds);
    _selectedFrequencies = List.from(widget.initialFilterData.frequencies);
    _startDay = (widget.initialFilterData.startDay ?? 1).toDouble();
    _endDay = (widget.initialFilterData.endDay ?? 31).toDouble();
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _handleApply() {
    final minAmount = double.tryParse(
      _minAmountController.text.replaceAll(',', '.'),
    );
    final maxAmount = double.tryParse(
      _maxAmountController.text.replaceAll(',', '.'),
    );

    final startDay = _startDay.round();
    final endDay = _endDay.round();
    final filterData = ExpenseFilterData(
      startDay: (startDay == 1 && endDay == 31) ? null : startDay,
      endDay: (startDay == 1 && endDay == 31) ? null : endDay,
      minAmount: minAmount,
      maxAmount: maxAmount,
      categoryIds: _selectedCategoryIds,
      accountIds: _selectedAccountIds,
      frequencies: _selectedFrequencies,
    );

    widget.onApply(filterData);
    Navigator.pop(context);
  }

  void _handleClear() {
    widget.onClear();
    Navigator.pop(context);
  }

  void _toggleCategory(int id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }

  void _toggleAccount(int id) {
    setState(() {
      if (_selectedAccountIds.contains(id)) {
        _selectedAccountIds.remove(id);
      } else {
        _selectedAccountIds.add(id);
      }
    });
  }

  void _toggleFrequency(String label) {
    setState(() {
      if (_selectedFrequencies.contains(label)) {
        _selectedFrequencies.remove(label);
      } else {
        _selectedFrequencies.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Période (jour du mois)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Du ${_startDay.round()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              'au ${_endDay.round()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        FrostedRangeSlider(
          values: RangeValues(_startDay, _endDay),
          min: 1,
          max: 31,
          divisions: 30,
          labels: RangeLabels(
            _startDay.round().toString(),
            _endDay.round().toString(),
          ),
          onChanged: (values) {
            setState(() {
              _startDay = values.start;
              _endDay = values.end;
            });
          },
        ),

        const SizedBox(height: 16),

        Text(
          'Montant',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FrostedTextField(
                controller: _minAmountController,
                labelText: 'Min',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.euro),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FrostedTextField(
                controller: _maxAmountController,
                labelText: 'Max',
                hintText: '∞',
                prefixIcon: const Icon(Icons.euro),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Text(
          'Fréquence',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'Mensuel',
              isSelected: _selectedFrequencies.contains('Mensuel'),
              onTap: () => _toggleFrequency('Mensuel'),
            ),
            _FilterChip(
              label: 'Annuel',
              isSelected: _selectedFrequencies.contains('Annuel'),
              onTap: () => _toggleFrequency('Annuel'),
            ),
            _FilterChip(
              label: 'Ponctuel',
              isSelected: _selectedFrequencies.contains('Ponctuel'),
              onTap: () => _toggleFrequency('Ponctuel'),
            ),
          ],
        ),

        const SizedBox(height: 24),

        if (widget.categories.isNotEmpty) ...[
          Text(
            'Catégories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.categories.map((category) {
                  final isSelected = _selectedCategoryIds.contains(category.id);
                  return _FilterChip(
                    label: category.name,
                    isSelected: isSelected,
                    onTap: () => _toggleCategory(category.id),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        if (widget.accounts.isNotEmpty) ...[
          Text(
            'Comptes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.accounts.map((account) {
                  final isSelected = _selectedAccountIds.contains(account.id);
                  return _FilterChip(
                    label: account.name,
                    isSelected: isSelected,
                    onTap: () => _toggleAccount(account.id),
                  );
                }).toList(),
          ),
          const SizedBox(height: 32),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FrostedTextButton(
              onPressed: _handleClear,
              child: const Text('Effacer'),
            ),
            const SizedBox(width: 8),
            FrostedTextButton(
              onPressed: () {
                widget.onCancel();
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 16),
            FrostedFilledButton(
              onPressed: _handleApply,
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ],
    ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.1,
                  ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
