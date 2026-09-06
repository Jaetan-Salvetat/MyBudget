import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/services/amount_slider_scale.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/transaction_filter_data.dart';

class TransactionFilterBottomSheet extends StatefulWidget {
  final TransactionFilterData initialFilterData;
  final List<CategoryDisplay> categories;
  final List<AccountModel> accounts;
  final List<Beneficiary> beneficiaries;
  final double highestAmount;
  final int Function(TransactionFilterData filter) resultCount;
  final void Function(TransactionFilterData filter) onApply;

  const TransactionFilterBottomSheet({
    required this.initialFilterData,
    required this.categories,
    required this.accounts,
    required this.beneficiaries,
    required this.highestAmount,
    required this.resultCount,
    required this.onApply,
    super.key,
  });

  static void show({
    required BuildContext context,
    required String title,
    required TransactionFilterData initialFilterData,
    required List<CategoryDisplay> categories,
    required List<AccountModel> accounts,
    required List<Beneficiary> beneficiaries,
    required double highestAmount,
    required int Function(TransactionFilterData filter) resultCount,
    required void Function(TransactionFilterData filter) onApply,
  }) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: title,
        child: TransactionFilterBottomSheet(
          initialFilterData: initialFilterData,
          categories: categories,
          accounts: accounts,
          beneficiaries: beneficiaries,
          highestAmount: highestAmount,
          resultCount: resultCount,
          onApply: onApply,
        ),
      ),
    );
  }

  @override
  State<TransactionFilterBottomSheet> createState() =>
      _TransactionFilterBottomSheetState();
}

class _TransactionFilterBottomSheetState
    extends State<TransactionFilterBottomSheet> {
  late final AmountSliderScale _amountScale;

  List<String> _selectedGroupKeys = [];
  List<int> _selectedAccountIds = [];
  List<int> _selectedBeneficiaryIds = [];
  List<Frequency> _selectedTypes = [];
  late RangeValues _amountRange;

  @override
  void initState() {
    super.initState();
    _amountScale = AmountSliderScale.forHighest(widget.highestAmount);
    _selectedGroupKeys = List.from(widget.initialFilterData.groupKeys);
    _selectedAccountIds = List.from(widget.initialFilterData.accountIds);
    _selectedBeneficiaryIds = List.from(
      widget.initialFilterData.beneficiaryIds,
    );
    _selectedTypes = List.from(widget.initialFilterData.types);
    final (minAmount, maxAmount) = _amountScale.clamp(
      widget.initialFilterData.minAmount,
      widget.initialFilterData.maxAmount,
    );
    _amountRange = RangeValues(minAmount, maxAmount);
  }

  TransactionFilterData _buildFilterData() {
    final hasMin = _amountRange.start > 0;
    final hasMax = _amountRange.end < _amountScale.ceiling;
    return TransactionFilterData(
      searchQuery: widget.initialFilterData.searchQuery,
      minAmount: hasMin ? _amountRange.start : null,
      maxAmount: hasMax ? _amountRange.end : null,
      groupKeys: _selectedGroupKeys,
      accountIds: _selectedAccountIds,
      beneficiaryIds: _selectedBeneficiaryIds,
      types: _selectedTypes,
    );
  }

  void _toggleCategory(String key) {
    setState(() {
      _selectedGroupKeys = _toggled(_selectedGroupKeys, key);
    });
  }

  void _toggleAccount(int id) {
    setState(() {
      _selectedAccountIds = _toggled(_selectedAccountIds, id);
    });
  }

  void _toggleBeneficiary(int id) {
    setState(() {
      _selectedBeneficiaryIds = _toggled(_selectedBeneficiaryIds, id);
    });
  }

  void _toggleType(Frequency type) {
    setState(() {
      _selectedTypes = _toggled(_selectedTypes, type);
    });
  }

  List<T> _toggled<T>(List<T> values, T value) {
    if (values.contains(value)) {
      return values.where((current) => current != value).toList();
    }
    return [...values, value];
  }

  void _handleReset() {
    setState(() {
      _selectedGroupKeys = [];
      _selectedAccountIds = [];
      _selectedBeneficiaryIds = [];
      _selectedTypes = [];
      _amountRange = RangeValues(0, _amountScale.ceiling);
    });
  }

  void _handleApply() {
    widget.onApply(_buildFilterData());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.resultCount(_buildFilterData());

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _GroupLabel(text: 'Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final type in Frequency.values)
                _Chip(
                  label: type.label,
                  icon: _typeIcon(type),
                  selected: _selectedTypes.contains(type),
                  onTap: () => _toggleType(type),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (widget.categories.isNotEmpty) ...[
            _GroupLabel(
              text: 'Catégories',
              hint: _selectionHint(_selectedGroupKeys.length),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.categories.map((category) {
                return _Chip(
                  label: category.label,
                  color: Color(category.color),
                  selected: _selectedGroupKeys.contains(category.slug),
                  onTap: () => _toggleCategory(category.slug),
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
            max: _amountScale.ceiling,
            divisions: _amountScale.divisions,
            onChanged: (values) {
              setState(() => _amountRange = values);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AmountBound(label: '0 €'),
              _AmountBound(label: '${_amountScale.ceiling.round()} €'),
            ],
          ),
          const SizedBox(height: 20),

          if (widget.accounts.isNotEmpty) ...[
            const _GroupLabel(text: 'Compte'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.accounts.map((account) {
                return _Chip(
                  label: account.name,
                  icon: Symbols.account_balance_wallet_rounded,
                  selected: _selectedAccountIds.contains(account.id),
                  onTap: () => _toggleAccount(account.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          if (widget.beneficiaries.isNotEmpty) ...[
            _GroupLabel(
              text: 'Bénéficiaire',
              hint: _selectionHint(_selectedBeneficiaryIds.length),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.beneficiaries.map((beneficiary) {
                return _Chip(
                  label: beneficiary.name,
                  color: Color(beneficiary.color),
                  selected: _selectedBeneficiaryIds.contains(beneficiary.id),
                  onTap: () => _toggleBeneficiary(beneficiary.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: FrostedButton.outlined(
                  label: 'Réinitialiser',
                  onPressed: _handleReset,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FrostedButton.filled(
                  label: 'Voir $count résultats',
                  onPressed: _handleApply,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static IconData _typeIcon(Frequency type) {
    return switch (type) {
      Frequency.monthly => Symbols.event_repeat_rounded,
      Frequency.annual => Symbols.calendar_month_rounded,
      Frequency.oneTime => Symbols.circle_rounded,
    };
  }

  static String? _selectionHint(int count) {
    if (count == 0) return null;
    return '$count sélectionné${count > 1 ? 's' : ''}';
  }
}

class _AmountBound extends StatelessWidget {
  final String label;

  const _AmountBound({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
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
    return FrostedChip.filter(
      label: label,
      selected: selected,
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
      onSelected: (_) => onTap(),
    );
  }
}
