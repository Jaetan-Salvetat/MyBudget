import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/revenue_filter_data.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/core/entities/beneficiary.dart';

class RevenueFilterBottomSheet extends StatefulWidget {
  final RevenueFilterData initialFilterData;
  final List<AccountModel> accounts;
  final List<Beneficiary> beneficiaries;
  final Function(RevenueFilterData) onApply;
  final VoidCallback onClear;
  final VoidCallback onCancel;

  const RevenueFilterBottomSheet({
    required this.initialFilterData,
    required this.accounts,
    required this.beneficiaries,
    required this.onApply,
    required this.onClear,
    required this.onCancel,
    super.key,
  });

  static void show({
    required BuildContext context,
    required RevenueFilterData initialFilterData,
    required List<AccountModel> accounts,
    required List<Beneficiary> beneficiaries,
    required Function(RevenueFilterData) onApply,
    required VoidCallback onClear,
    required VoidCallback onCancel,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Filtrer les revenus',
      child: RevenueFilterBottomSheet(
        initialFilterData: initialFilterData,
        accounts: accounts,
        beneficiaries: beneficiaries,
        onApply: onApply,
        onClear: onClear,
        onCancel: onCancel,
      ),
    );
  }

  @override
  State<RevenueFilterBottomSheet> createState() =>
      _RevenueFilterBottomSheetState();
}

class _RevenueFilterBottomSheetState extends State<RevenueFilterBottomSheet> {
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  List<int> _selectedAccountIds = [];
  List<int> _selectedBeneficiaryIds = [];
  List<String> _selectedFrequencies = [];

  @override
  void initState() {
    super.initState();
    _minAmountController = TextEditingController(
      text: widget.initialFilterData.minAmount?.toString() ?? '',
    );
    _maxAmountController = TextEditingController(
      text: widget.initialFilterData.maxAmount?.toString() ?? '',
    );
    _selectedAccountIds = List.from(widget.initialFilterData.accountIds);
    _selectedBeneficiaryIds = List.from(widget.initialFilterData.beneficiaryIds);
    _selectedFrequencies = List.from(widget.initialFilterData.frequencies);
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

    final filterData = RevenueFilterData(
      minAmount: minAmount,
      maxAmount: maxAmount,
      accountIds: _selectedAccountIds,
      beneficiaryIds: _selectedBeneficiaryIds,
      frequencies: _selectedFrequencies,
    );

    widget.onApply(filterData);
    Navigator.pop(context);
  }

  void _handleClear() {
    widget.onClear();
    Navigator.pop(context);
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

  void _toggleBeneficiary(int id) {
    setState(() {
      if (_selectedBeneficiaryIds.contains(id)) {
        _selectedBeneficiaryIds.remove(id);
      } else {
        _selectedBeneficiaryIds.add(id);
      }
    });
  }

  void _toggleFrequency(String frequency) {
    setState(() {
      if (_selectedFrequencies.contains(frequency)) {
        _selectedFrequencies.remove(frequency);
      } else {
        _selectedFrequencies.add(frequency);
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
                prefixIcon: const Icon(Symbols.euro_rounded),
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
                prefixIcon: const Icon(Symbols.euro_rounded),
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

        if (widget.accounts.isNotEmpty) ...[
          const SizedBox(height: 24),
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
            children: widget.accounts.map((account) {
              final isSelected = _selectedAccountIds.contains(account.id);
              return _FilterChip(
                label: account.name,
                isSelected: isSelected,
                onTap: () => _toggleAccount(account.id),
              );
            }).toList(),
          ),
        ],

        if (widget.beneficiaries.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Bénéficiaires',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.beneficiaries.map((b) {
              final isSelected = _selectedBeneficiaryIds.contains(b.id);
              return _FilterChip(
                label: b.name,
                isSelected: isSelected,
                onTap: () => _toggleBeneficiary(b.id),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 32),

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
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
