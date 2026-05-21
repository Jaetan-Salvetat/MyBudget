import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_filter_data.dart';

class ExpenseFilterBottomSheet extends StatefulWidget {
  final ExpenseFilterData initialFilterData;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final int Function(ExpenseFilterData) resultCount;
  final Function(ExpenseFilterData) onApply;
  final VoidCallback onClear;
  final VoidCallback onCancel;

  const ExpenseFilterBottomSheet({
    required this.initialFilterData,
    required this.categories,
    required this.accounts,
    required this.resultCount,
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
    required int Function(ExpenseFilterData) resultCount,
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
        resultCount: resultCount,
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
  static const double _maxAmountSliderValue = 1000;

  List<int> _selectedCategoryIds = [];
  List<int> _selectedAccountIds = [];
  List<Frequency> _selectedTypes = [];
  RangeValues _amountRange = const RangeValues(0, _maxAmountSliderValue);

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = List.from(widget.initialFilterData.categoryIds);
    _selectedAccountIds = List.from(widget.initialFilterData.accountIds);
    _selectedTypes = List.from(widget.initialFilterData.types);
    _amountRange = RangeValues(
      widget.initialFilterData.minAmount ?? 0,
      widget.initialFilterData.maxAmount ?? _maxAmountSliderValue,
    );
  }

  ExpenseFilterData _buildFilterData() {
    final hasMin = _amountRange.start > 0;
    final hasMax = _amountRange.end < _maxAmountSliderValue;
    return ExpenseFilterData(
      searchQuery: widget.initialFilterData.searchQuery,
      minAmount: hasMin ? _amountRange.start : null,
      maxAmount: hasMax ? _amountRange.end : null,
      categoryIds: _selectedCategoryIds,
      accountIds: _selectedAccountIds,
      types: _selectedTypes,
    );
  }

  void _toggleCategory(int id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds = [..._selectedCategoryIds, id];
      }
    });
  }

  void _toggleAccount(int id) {
    setState(() {
      if (_selectedAccountIds.contains(id)) {
        _selectedAccountIds.remove(id);
      } else {
        _selectedAccountIds = [..._selectedAccountIds, id];
      }
    });
  }

  void _toggleType(Frequency type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes = [..._selectedTypes, type];
      }
    });
  }

  void _handleReset() {
    setState(() {
      _selectedCategoryIds = [];
      _selectedAccountIds = [];
      _selectedTypes = [];
      _amountRange = const RangeValues(0, _maxAmountSliderValue);
    });
  }

  void _handleApply() {
    widget.onApply(_buildFilterData());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentFilter = _buildFilterData();
    final count = widget.resultCount(currentFilter);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupLabel(text: 'Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Chip(
                label: 'Mensuel',
                icon: Symbols.event_repeat_rounded,
                selected: _selectedTypes.contains(Frequency.monthly),
                onTap: () => _toggleType(Frequency.monthly),
              ),
              _Chip(
                label: 'Annuel',
                icon: Symbols.calendar_month_rounded,
                selected: _selectedTypes.contains(Frequency.annual),
                onTap: () => _toggleType(Frequency.annual),
              ),
              _Chip(
                label: 'Ponctuel',
                icon: Symbols.circle_rounded,
                selected: _selectedTypes.contains(Frequency.oneTime),
                onTap: () => _toggleType(Frequency.oneTime),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (widget.categories.isNotEmpty) ...[
            _GroupLabel(
              text: 'Catégories',
              hint: _selectedCategoryIds.isNotEmpty
                  ? '${_selectedCategoryIds.length} sélectionnée${_selectedCategoryIds.length > 1 ? 's' : ''}'
                  : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.categories.map((category) {
                final selected = _selectedCategoryIds.contains(category.id);
                return _Chip(
                  label: category.name,
                  color: Color(category.color),
                  selected: selected,
                  onTap: () => _toggleCategory(category.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          _GroupLabel(
            text: 'Montant',
            hint:
                '${_amountRange.start.round()} € – ${_amountRange.end.round()} €',
          ),
          const SizedBox(height: 4),
          FrostedRangeSlider(
            values: _amountRange,
            min: 0,
            max: _maxAmountSliderValue,
            divisions: 100,
            onChanged: (values) {
              setState(() => _amountRange = values);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 €',
                style: TextStyle(
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${_maxAmountSliderValue.round()} €',
                style: TextStyle(
                  fontSize: 11,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (widget.accounts.isNotEmpty) ...[
            _GroupLabel(text: 'Compte'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.accounts.map((account) {
                final selected = _selectedAccountIds.contains(account.id);
                return _Chip(
                  label: account.name,
                  icon: Symbols.account_balance_wallet_rounded,
                  selected: selected,
                  onTap: () => _toggleAccount(account.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          Row(
            children: [
              Expanded(
                child: FrostedOutlinedButton(
                  onPressed: _handleReset,
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FrostedFilledButton(
                  onPressed: _handleApply,
                  child: Text('Voir $count résultats'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  final String? hint;

  const _GroupLabel({required this.text, this.hint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            height: 14 / 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.09 * 11,
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (hint != null) ...[
          const Spacer(),
          Text(
            hint!,
            style: TextStyle(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: scheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedChip(
      label: Text(label),
      selected: selected,
      selectedColor: color,
      avatar: icon != null
          ? Icon(icon, size: 14)
          : color != null
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color!.withValues(alpha: selected ? 0.9 : 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                )
              : null,
      onPressed: onTap,
    );
  }
}
