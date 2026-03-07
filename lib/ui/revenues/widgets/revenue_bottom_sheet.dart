import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_selector.dart';
import 'package:mybudget/ui/common/widgets/frosted_date_selector.dart';

class RevenueBottomSheet extends StatefulWidget {
  final List<AccountModel> accounts;
  final List<BeneficiaryModel> beneficiaries;
  final RevenueModel? revenue;
  final Function(RevenueModel) onSubmit;
  final Function(String) onCreateBeneficiary;
  final VoidCallback onCancel;

  const RevenueBottomSheet({
    required this.accounts,
    required this.beneficiaries,
    required this.onSubmit,
    required this.onCreateBeneficiary,
    required this.onCancel,
    this.revenue,
    super.key,
  });

  static void show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required List<BeneficiaryModel> beneficiaries,
    required Function(RevenueModel) onSubmit,
    required Function(String) onCreateBeneficiary,
    required VoidCallback onCancel,
    RevenueModel? revenue,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: revenue == null ? 'Ajouter un revenu' : 'Modifier le revenu',
      child: RevenueBottomSheet(
        accounts: accounts,
        beneficiaries: beneficiaries,
        onSubmit: onSubmit,
        onCreateBeneficiary: onCreateBeneficiary,
        onCancel: onCancel,
        revenue: revenue,
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
  int? _selectedAccountId;
  String? _accountError;
  String? _nameError;
  String? _amountError;

  // -1 = nouveau bénéficiaire à créer, null = aucun, >0 = id existant
  int? _selectedBeneficiaryId;
  final _beneficiarySelectorKey = GlobalKey<BeneficiarySelectorState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.revenue?.name ?? '');
    _amountController = TextEditingController(
      text: widget.revenue?.amount.toString() ?? '',
    );

    _selectedDate = widget.revenue?.date ?? DateTime.now();
    _selectedAccountId =
        widget.revenue?.accountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
    _selectedBeneficiaryId = widget.revenue?.beneficiaryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
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

    int? resolvedBeneficiaryId = _selectedBeneficiaryId;

    if (_selectedBeneficiaryId == -1) {
      final pendingName =
          _beneficiarySelectorKey.currentState?.pendingNewName;
      if (pendingName != null && pendingName.isNotEmpty) {
        widget.onCreateBeneficiary(pendingName);
        resolvedBeneficiaryId = null;
      }
    }

    final revenue =
        widget.revenue != null
            ? widget.revenue!.copyWith(
              name: _nameController.text.trim(),
              amount: amount,
              isRegular: true,
              date: _selectedDate,
              accountId: _selectedAccountId!,
              beneficiaryId: resolvedBeneficiaryId,
            )
            : RevenueModel.create(
              name: _nameController.text.trim(),
              amount: amount,
              isRegular: true,
              date: _selectedDate,
              accountId: _selectedAccountId!,
              beneficiaryId: resolvedBeneficiaryId,
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

          Text(
            'Date de versement',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          InkWell(
            onTap: () async {
              final picked = await FrostedDateSelector.showDayPicker(
                context: context,
                initialDate: _selectedDate,
              );

              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Jour du mois',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.3),
              ),
              child: Text("Le ${_selectedDate.day} du mois"),
            ),
          ),

          const SizedBox(height: 24),

          BeneficiarySelector(
            key: _beneficiarySelectorKey,
            beneficiaries: widget.beneficiaries,
            initialBeneficiaryId: widget.revenue?.beneficiaryId,
            onChanged: (id) => setState(() => _selectedBeneficiaryId = id),
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
                onPressed: _handleSubmit,
                child: Text(widget.revenue == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
