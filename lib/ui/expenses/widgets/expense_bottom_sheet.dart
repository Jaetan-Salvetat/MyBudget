import 'package:flutter/material.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/ui/expenses/widgets/expense_frequency_date_section.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ExpenseBottomSheet(
              accounts: accounts,
              categories: categories,
              onSubmit: onSubmit,
              onCancel: onCancel,
              expense: expense,
            ),
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
  int _selectedCategoryId = 0;
  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = 'Mensuel';
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );

    _selectedCategoryId =
        widget.expense?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : 0);
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedFrequency = widget.expense?.frequency ?? 'Mensuel';
    _selectedAccountId =
        widget.expense?.accountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    final expense =
        widget.expense != null
            ? widget.expense!.copyWith(
              name: _nameController.text.trim(),
              amount: amount,
              categoryId: _selectedCategoryId,
              date: _selectedDate,
              frequency: _selectedFrequency,
              accountId: _selectedAccountId!,
            )
            : ExpenseModel.create(
              name: _nameController.text.trim(),
              amount: amount,
              categoryId: _selectedCategoryId,
              date: _selectedDate,
              frequency: _selectedFrequency,
              accountId: _selectedAccountId!,
            );

    widget.onSubmit(expense);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.expense == null
                  ? 'Ajouter une dépense'
                  : 'Modifier la dépense',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

             
            Text(
              'Informations',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Montant',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
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
                  });
                }
              },
              validator: (value) {
                if (value == null || value == 0) {
                  return 'Veuillez sélectionner une catégorie';
                }
                return null;
              },
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
            DropdownButtonFormField<int>(
              value: _selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Compte associé',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
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
                  });
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner un compte';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onCancel();
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _handleSubmit,
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
