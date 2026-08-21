import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/ui/common/widgets/category_field.dart';
import 'package:mybudget/ui/common/widgets/category_picker_sheet.dart';
import 'package:mybudget/ui/common/expense_frequency_date_section.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_selector.dart';

class ExpenseBottomSheet extends ConsumerStatefulWidget {
  final List<AccountModel> accounts;
  final ExpenseModel? expense;
  final List<ExpenseModel> closedExpenses;
  final Function(ExpenseModel) onSubmit;
  final VoidCallback onCancel;

  const ExpenseBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.expense,
    this.closedExpenses = const [],
    super.key,
  });

  static void show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required Function(ExpenseModel) onSubmit,
    required VoidCallback onCancel,
    ExpenseModel? expense,
    List<ExpenseModel> closedExpenses = const [],
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: expense == null ? 'Ajouter une dépense' : 'Modifier la dépense',
      child: ExpenseBottomSheet(
        accounts: accounts,
        onSubmit: onSubmit,
        onCancel: onCancel,
        expense: expense,
        closedExpenses: closedExpenses,
      ),
    );
  }

  @override
  ConsumerState<ExpenseBottomSheet> createState() =>
      _ExpenseBottomSheetState();
}

class _ExpenseBottomSheetState extends ConsumerState<ExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  String? _selectedCategorySlug;
  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = 'Mensuel';
  int? _selectedAccountId;
  String? _categoryError;
  String? _accountError;
  String? _amountError;

  int? _selectedBeneficiaryId;
  bool _beneficiaryEnabled = false;
  int? _parentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );

    _selectedCategorySlug = widget.expense?.categorySlug;
    _selectedDate = widget.expense?.startDate ?? DateTime.now();
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
      if (_selectedCategorySlug == null) {
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
              categorySlug: _selectedCategorySlug,
              startDate: _selectedDate,
              frequency: _selectedFrequency,
              accountId: _selectedAccountId!,
              beneficiaryId: _selectedBeneficiaryId,
            )
            : ExpenseModel.create(
              name: _nameController.text.trim(),
              amount: amount,
              categorySlug: _selectedCategorySlug,
              startDate: _selectedDate,
              frequency: _selectedFrequency,
              accountId: _selectedAccountId!,
              beneficiaryId: _selectedBeneficiaryId,
              parentId: _parentId,
            );

    widget.onSubmit(expense);
    Navigator.pop(context);
  }

  void _fillFromClosedExpense(ExpenseModel closed) {
    setState(() {
      _nameController.text = closed.name;
      _amountController.text = closed.amount.toString();
      _selectedCategorySlug = closed.categorySlug;
      _selectedFrequency = closed.frequency;
      _selectedAccountId = closed.accountId;
      _selectedBeneficiaryId = closed.beneficiaryId;
      _beneficiaryEnabled = closed.beneficiaryId != null;
      _parentId = closed.parentId ?? closed.id;
      _selectedDate = DateTime.now();
    });
  }

  void _showClosedExpensePicker(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    FrostedDialog.show(
      context: context,
      title: const Text('Reprendre une dépense'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.closedExpenses.length,
          itemBuilder: (context, index) {
            final expense = widget.closedExpenses[index];
            return FrostedListTile(
              title: Text(expense.name),
              subtitle: Text(formatter.format(expense.amount)),
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                _fillFromClosedExpense(expense);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.expense == null && widget.closedExpenses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FrostedTextButton(
                  onPressed: () => _showClosedExpensePicker(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Symbols.history_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Reprendre une ancienne dépense'),
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
              hintText: 'Ex: Loyer',
              prefixIcon: const Icon(Symbols.edit_rounded),
            ),
            const SizedBox(height: 16),
            FrostedTextField(
              controller: _amountController,
              labelText: 'Montant',
              hintText: '0.00',
              prefixIcon: const Icon(Symbols.euro_rounded),
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
                CategoryField(
                  slug: _selectedCategorySlug,
                  onTap: _pickCategory,
                ),
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

  Future<void> _pickCategory() async {
    final slug = await CategoryPickerSheet.show(
      context,
      selectedSlug: _selectedCategorySlug,
    );
    if (slug == null || !mounted) return;
    setState(() {
      _selectedCategorySlug = slug;
      _categoryError = null;
    });
  }
}
