import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/ui/common/expense_frequency_date_section.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_selector.dart';

class ExpenseBottomSheet extends StatefulWidget {
  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
  final ExpenseModel? expense;
  final Function(ExpenseModel) onSubmit;
  final VoidCallback onCancel;

  const ExpenseBottomSheet({
    required this.accounts,
    required this.categories,
    required this.onSubmit,
    required this.onCancel,
    this.expense,
    super.key,
  });

  static void show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required List<CategoryModel> categories,
    required Function(ExpenseModel) onSubmit,
    required VoidCallback onCancel,
    ExpenseModel? expense,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: expense == null ? 'Ajouter une dépense' : 'Modifier la dépense',
      child: ExpenseBottomSheet(
        accounts: accounts,
        categories: categories,
        onSubmit: onSubmit,
        onCancel: onCancel,
        expense: expense,
      ),
    );
  }

  @override
  State<ExpenseBottomSheet> createState() => _ExpenseBottomSheetState();
}

class _ExpenseBottomSheetState extends State<ExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = 'Mensuel';
  int? _selectedAccountId;
  String? _categoryError;
  String? _accountError;
  String? _amountError;

  // null = aucun ou switch OFF, >0 = id existant sélectionné
  int? _selectedBeneficiaryId;
  bool _beneficiaryEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );

    _selectedCategoryId =
        widget.expense?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedFrequency = widget.expense?.frequency ?? 'Mensuel';
    _selectedAccountId =
        widget.expense?.accountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
    _selectedBeneficiaryId = widget.expense?.beneficiaryId;
    _beneficiaryEnabled = widget.expense?.beneficiaryId != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool _validateDropdowns() {
    bool isValid = true;
    setState(() {
      if (_selectedCategoryId == null) {
        _categoryError = 'Veuillez sélectionner une catégorie';
        isValid = false;
      } else {
        _categoryError = null;
      }

      if (_selectedAccountId == null) {
        _accountError = 'Veuillez sélectionner un compte';
        isValid = false;
      } else {
        _accountError = null;
      }
    });
    return isValid;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || !_validateDropdowns()) {
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    if (amount <= 0) {
      setState(() {
        _amountError = 'Le montant doit être supérieur à 0';
      });
      return;
    } else {
      setState(() {
        _amountError = null;
      });
    }

    final expense =
        widget.expense != null
            ? widget.expense!.copyWith(
              name: _nameController.text.trim(),
              amount: amount,
              categoryId: _selectedCategoryId!,
              date: _selectedDate,
              frequency: _selectedFrequency,
              accountId: _selectedAccountId!,
              beneficiaryId: _selectedBeneficiaryId,
            )
            : ExpenseModel.create(
              name: _nameController.text.trim(),
              amount: amount,
              categoryId: _selectedCategoryId!,
              date: _selectedDate,
              frequency: _selectedFrequency,
              accountId: _selectedAccountId!,
              beneficiaryId: _selectedBeneficiaryId,
            );

    widget.onSubmit(expense);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom
        + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Form(
        key: _formKey,
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
              hintText: 'Ex: Loyer',
              prefixIcon: const Icon(Icons.edit),
            ),
            const SizedBox(height: 16),
            FrostedTextField(
              controller: _amountController,
              labelText: 'Montant',
              hintText: '0.00',
              prefixIcon: const Icon(Icons.euro),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
            const SizedBox(height: 16),

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
                FrostedDropdown<int>(
                  value: _selectedCategoryId,
                  items:
                      widget.categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategoryId = value;
                        _categoryError = null;
                      });
                    }
                  },
                ),
                if (widget.categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Text(
                      'Aucune catégorie disponible. Veuillez en créer une dans les paramètres.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (_categoryError != null)
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
              ],
            ),

            const SizedBox(height: 24),

            ExpenseFrequencyDateSection(
              frequency: _selectedFrequency,
              date: _selectedDate,
              onChanged: (freq, date) {
                setState(() {
                  _selectedFrequency = freq;
                  _selectedDate = date;
                });
              },
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

            BeneficiarySelector(
              initialBeneficiaryId: widget.expense?.beneficiaryId,
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
                  child: Text(
                    widget.expense == null ? 'Ajouter' : 'Enregistrer',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
