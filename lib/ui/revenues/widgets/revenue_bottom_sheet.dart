import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/ui/common/widgets/category_field.dart';
import 'package:mybudget/ui/common/widgets/category_picker_sheet.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/common/expense_frequency_date_section.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_selector.dart';

class RevenueBottomSheet extends ConsumerStatefulWidget {
  final List<AccountModel> accounts;
  final RevenueModel? revenue;
  final List<RevenueModel> closedRevenues;
  final Function(RevenueModel) onSubmit;
  final VoidCallback onCancel;

  const RevenueBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.revenue,
    this.closedRevenues = const [],
    super.key,
  });

  static void show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required Function(RevenueModel) onSubmit,
    required VoidCallback onCancel,
    RevenueModel? revenue,
    List<RevenueModel> closedRevenues = const [],
  }) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: revenue == null ? 'Ajouter un revenu' : 'Modifier le revenu',
        child: RevenueBottomSheet(
          accounts: accounts,
          onSubmit: onSubmit,
          onCancel: onCancel,
          revenue: revenue,
          closedRevenues: closedRevenues,
        ),
      ),
    );
  }

  @override
  ConsumerState<RevenueBottomSheet> createState() => _RevenueBottomSheetState();
}

class _RevenueBottomSheetState extends ConsumerState<RevenueBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now();
  late String _selectedFrequency;
  int? _selectedAccountId;
  String? _selectedCategorySlug;
  String? _categoryError;
  String? _accountError;
  String? _nameError;
  String? _amountError;

  int? _selectedBeneficiaryId;
  bool _beneficiaryEnabled = false;
  int? _parentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.revenue?.name ?? '');
    _amountController = TextEditingController(
      text: widget.revenue?.amount.toString() ?? '',
    );

    _selectedDate = widget.revenue?.startDate ?? DateTime.now();
    _selectedFrequency = widget.revenue?.frequency ?? Frequency.monthly.label;
    _selectedCategorySlug = widget.revenue?.categorySlug;
    _selectedAccountId =
        widget.revenue?.accountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
    _selectedBeneficiaryId = widget.revenue?.beneficiaryId;
    _beneficiaryEnabled = widget.revenue?.beneficiaryId != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _fillFromClosedRevenue(RevenueModel closed) {
    setState(() {
      _nameController.text = closed.name;
      _amountController.text = closed.amount.toString();
      _selectedFrequency = closed.frequency;
      _selectedAccountId = closed.accountId;
      _selectedCategorySlug = closed.categorySlug;
      _selectedBeneficiaryId = closed.beneficiaryId;
      _beneficiaryEnabled = closed.beneficiaryId != null;
      _parentId = closed.parentId ?? closed.id;
      _selectedDate = DateTime.now();
    });
  }

  void _showClosedRevenuePicker(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Reprendre un revenu',
        body: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.closedRevenues.length,
            itemBuilder: (context, index) {
              final revenue = widget.closedRevenues[index];
              return FrostedListTile(
                title: revenue.name,
                subtitle: formatter.format(revenue.amount),
                trailing: const Icon(Symbols.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  _fillFromClosedRevenue(revenue);
                },
              );
            },
          ),
        ),
        actions: [
          FrostedButton.text(
            label: 'Annuler',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    setState(() {
      _nameError = _nameController.text.isEmpty
          ? 'Veuillez saisir un nom'
          : null;
      _amountError = _amountController.text.isEmpty
          ? 'Veuillez saisir un montant'
          : null;
      _accountError = _selectedAccountId == null
          ? 'Veuillez sélectionner un compte'
          : null;
      _categoryError = _selectedCategorySlug == null
          ? 'Veuillez sélectionner une catégorie'
          : null;
    });

    if (_nameError != null ||
        _amountError != null ||
        _accountError != null ||
        _categoryError != null) {
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    if (amount <= 0) {
      setState(() {
        _amountError = 'Le montant doit être supérieur à 0';
      });
      return;
    }

    final revenue = widget.revenue != null
        ? widget.revenue!.copyWith(
            name: _nameController.text.trim(),
            amount: amount,
            startDate: _selectedDate,
            accountId: _selectedAccountId!,
            frequency: _selectedFrequency,
            beneficiaryId: _selectedBeneficiaryId,
            categorySlug: _selectedCategorySlug,
          )
        : RevenueModel.create(
            name: _nameController.text.trim(),
            amount: amount,
            startDate: _selectedDate,
            accountId: _selectedAccountId!,
            frequency: _selectedFrequency,
            beneficiaryId: _selectedBeneficiaryId,
            parentId: _parentId,
            categorySlug: _selectedCategorySlug,
          );

    widget.onSubmit(revenue);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.revenue == null && widget.closedRevenues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FrostedButton.text(
                label: 'Reprendre un ancien revenu',
                icon: Symbols.history_rounded,
                onPressed: () => _showClosedRevenuePicker(context),
              ),
            ),
          Text(
            'Informations',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          FrostedTextField(
            controller: _nameController,
            label: 'Nom',
            hintText: 'Ex: Salaire',
            leadingIcon: Symbols.edit_rounded,
          ),
          if (_nameError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Text(
                _nameError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),
          FrostedTextField(
            controller: _amountController,
            label: 'Montant',
            hintText: '0.00',
            leadingIcon: Symbols.euro_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (_amountError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Text(
                _amountError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 24),

          Text(
            'Compte',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catégorie',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              CategoryField(slug: _selectedCategorySlug, onTap: _pickCategory),
              if (_categoryError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    _categoryError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Compte associé',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              FrostedDropdown<int>(
                value: _selectedAccountId,
                items: widget.accounts.map((account) {
                  return FrostedDropdownItem<int>(
                    value: account.id,
                    label: account.name,
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccountId = value;
                    _accountError = null;
                  });
                },
              ),
              if (_accountError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    _accountError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          ExpenseFrequencyDateSection(
            frequency: _selectedFrequency,
            date: _selectedDate,
            onChanged: (frequency, date) {
              setState(() {
                _selectedFrequency = frequency;
                _selectedDate = date;
              });
            },
          ),

          const SizedBox(height: 24),

          BeneficiarySelector(
            initialBeneficiaryId: widget.revenue?.beneficiaryId,
            onChanged: (id) => setState(() {
              _selectedBeneficiaryId = id;
              _beneficiaryEnabled = id != null;
            }),
          ),

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FrostedButton.text(
                label: 'Annuler',
                onPressed: () {
                  widget.onCancel();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 16),
              FrostedButton.filled(
                label: widget.revenue == null ? 'Ajouter' : 'Enregistrer',
                onPressed: _beneficiaryEnabled && _selectedBeneficiaryId == null
                    ? null
                    : _handleSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickCategory() async {
    final slug = await CategoryPickerSheet.show(
      context,
      type: TransactionType.income,
      selectedSlug: _selectedCategorySlug,
    );
    if (slug == null || !mounted) return;
    setState(() {
      _selectedCategorySlug = slug;
      _categoryError = null;
    });
  }
}
