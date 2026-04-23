import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/common/expense_frequency_date_section.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_selector.dart';

class RevenueBottomSheet extends StatefulWidget {
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
    FrostedBottomSheet.show(
      context: context,
      title: revenue == null ? 'Ajouter un revenu' : 'Modifier le revenu',
      child: RevenueBottomSheet(
        accounts: accounts,
        onSubmit: onSubmit,
        onCancel: onCancel,
        revenue: revenue,
        closedRevenues: closedRevenues,
      ),
    );
  }

  @override
  State<RevenueBottomSheet> createState() => _RevenueBottomSheetState();
}

class _RevenueBottomSheetState extends State<RevenueBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now();
  late String _selectedFrequency;
  int? _selectedAccountId;
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
      _selectedBeneficiaryId = closed.beneficiaryId;
      _beneficiaryEnabled = closed.beneficiaryId != null;
      _parentId = closed.parentId ?? closed.id;
      _selectedDate = DateTime.now();
    });
  }

  void _showClosedRevenuePicker(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    FrostedDialog.show(
      context: context,
      title: const Text('Reprendre un revenu'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.closedRevenues.length,
          itemBuilder: (context, index) {
            final revenue = widget.closedRevenues[index];
            return FrostedListTile(
              title: Text(revenue.name),
              subtitle: Text(formatter.format(revenue.amount)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _fillFromClosedRevenue(revenue);
              },
            );
          },
        ),
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  void _handleSubmit() {
    setState(() {
      _nameError =
          _nameController.text.isEmpty ? 'Veuillez saisir un nom' : null;
      _amountError =
          _amountController.text.isEmpty ? 'Veuillez saisir un montant' : null;
      _accountError =
          _selectedAccountId == null ? 'Veuillez sélectionner un compte' : null;
    });

    if (_nameError != null || _amountError != null || _accountError != null) {
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

    final revenue =
        widget.revenue != null
            ? widget.revenue!.copyWith(
              name: _nameController.text.trim(),
              amount: amount,
              startDate: _selectedDate,
              accountId: _selectedAccountId!,
              frequency: _selectedFrequency,
              beneficiaryId: _selectedBeneficiaryId,
            )
            : RevenueModel.create(
              name: _nameController.text.trim(),
              amount: amount,
              startDate: _selectedDate,
              accountId: _selectedAccountId!,
              frequency: _selectedFrequency,
              beneficiaryId: _selectedBeneficiaryId,
              parentId: _parentId,
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
              child: FrostedTextButton(
                onPressed: () => _showClosedRevenuePicker(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Reprendre un ancien revenu'),
                  ],
                ),
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
            labelText: 'Nom',
            hintText: 'Ex: Salaire',
            prefixIcon: const Icon(Icons.edit),
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
            labelText: 'Montant',
            hintText: '0.00',
            prefixIcon: const Icon(Icons.euro),
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
                'Compte associé',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              FrostedDropdown<int>(
                value: _selectedAccountId,
                items:
                    widget.accounts.map((account) {
                      return DropdownMenuItem<int>(
                        value: account.id,
                        child: Text(account.name),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAccountId = value;
                      _accountError = null;
                    });
                  }
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
              FrostedTextButton(
                onPressed: () {
                  widget.onCancel();
                  Navigator.pop(context);
                },
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 16),
              FrostedFilledButton(
                onPressed: _beneficiaryEnabled && _selectedBeneficiaryId == null
                    ? null
                    : _handleSubmit,
                child: Text(widget.revenue == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
