import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/domain/entities/expense.dart';
import 'package:mybudget/presentation/providers/category_provider.dart';
import 'package:mybudget/presentation/widgets/common/app_text_field.dart';
import 'package:mybudget/presentation/widgets/common/app_dropdown_field.dart';
import 'package:mybudget/presentation/widgets/expenses/adaptive_date_picker.dart';
import 'package:mybudget/presentation/widgets/expenses/frequency_selector.dart';

class ExpenseForm extends ConsumerStatefulWidget {
  final List<Account> accounts;
  final Expense? expense;
  final Function(Expense) onSubmit;
  final Function() onCancel;

  const ExpenseForm({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.expense,
    super.key,
  });

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  String selectedCategory = '';
  DateTime selectedDate = DateTime.now();
  String selectedFrequency = 'Unique';
  String? selectedAccountId;

  final List<String> frequencies = [
    'Unique',
    'Hebdomadaire',
    'Mensuel',
    'Annuel',
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final categories = ref.read(categoryNotifierProvider);
      if (categories.isNotEmpty && selectedCategory.isEmpty) {
        setState(() {
          selectedCategory = categories.first.name;
        });
      }
    });

    if (widget.expense != null) {
      nameController.text = widget.expense!.name;
      amountController.text = widget.expense!.amount.toString();
      selectedCategory = widget.expense!.category;
      selectedDate = widget.expense!.date;
      selectedFrequency = widget.expense!.frequency;
      selectedAccountId = widget.expense!.accountId;
    } else if (widget.accounts.isNotEmpty) {
      selectedAccountId = widget.accounts.first.id;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'gas_station':
        return Icons.local_gas_station;
      case 'home':
        return Icons.home;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) {
      return AlertDialog(
        title: const Text('Aucun compte disponible'),
        content: const Text(
          'Vous devez d\'abord créer un compte avant d\'ajouter une dépense.',
        ),
        actions: [
          TextButton(onPressed: widget.onCancel, child: const Text('OK')),
        ],
      );
    }

    return AlertDialog(
      title: Text(
        widget.expense == null ? 'Ajouter une dépense' : 'Modifier la dépense',
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            AppTextField(
              controller: nameController,
              label: 'Nom',
              icon: Icons.edit,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: amountController,
              label: 'Montant',
              icon: Icons.euro,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            AppDropdownField<String>(
              value: selectedCategory,
              label: 'Catégorie',
              icon: Icons.category,
              items:
                  ref.watch(categoryNotifierProvider).map((category) {
                    return DropdownMenuItem(
                      value: category.name,
                      child: Row(
                        children: [
                          Icon(_getIconData(category.icon)),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            FrequencySelector(
              selectedFrequency: selectedFrequency,
              frequencies: frequencies,
              onFrequencyChanged: (value) {
                setState(() {
                  selectedFrequency = value;
                });
              },
            ),
            const SizedBox(height: 16),
            AdaptiveDatePicker(
              selectedDate: selectedDate,
              frequency: selectedFrequency,
              onDateChanged: (date) {
                setState(() {
                  selectedDate = date;
                });
              },
            ),
            const SizedBox(height: 16),
            AppDropdownField<String>(
              value: selectedAccountId ?? '',
              label: 'Compte',
              icon: Icons.account_balance,
              items:
                  widget.accounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedAccountId = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isNotEmpty &&
                amountController.text.isNotEmpty &&
                selectedAccountId != null) {
              final amount =
                  double.tryParse(amountController.text.replaceAll(',', '.')) ??
                  0.0;

              final expense = ExpenseModel(
                id:
                    widget.expense?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                amount: amount,
                category: selectedCategory,
                date: selectedDate,
                frequency: selectedFrequency,
                accountId: selectedAccountId!,
              );

              widget.onSubmit(expense);
            }
          },
          child: Text(widget.expense == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }
}
