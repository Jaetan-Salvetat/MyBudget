import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/data/models/expense_model.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/presentation/widgets/common/app_text_field.dart';
import 'package:mybudget/presentation/widgets/common/app_dropdown_field.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/expenses/expense_date_picker.dart';
import 'package:mybudget/presentation/widgets/expenses/frequency_selector.dart';

class ExpenseBottomSheet extends StatefulWidget {
  final List<AccountModel> accounts;
  final ExpenseModel? expense;
  final Function(ExpenseModel) onSubmit;
  final Function() onCancel;

  const ExpenseBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.expense,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required Function(ExpenseModel) onSubmit,
    required Function() onCancel,
    ExpenseModel? expense,
  }) {
    if (accounts.isEmpty) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aucun compte disponible'),
          content: const Text(
            'Vous devez d\'abord créer un compte avant d\'ajouter une dépense.'
          ),
          actions: [
            TextButton(
              onPressed: onCancel,
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    return AppModalBottomSheet.show(
      context: context,
      title: expense == null ? 'Ajouter une dépense' : 'Modifier la dépense',
      content: ExpenseBottomSheet(
        accounts: accounts,
        onSubmit: onSubmit,
        onCancel: onCancel,
        expense: expense,
      ),
      actions: const [],
      isScrollable: true,
    );
  }

  @override
  State<ExpenseBottomSheet> createState() => _ExpenseBottomSheetState();
}

class _ExpenseBottomSheetState extends State<ExpenseBottomSheet> {
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
      final categoryController = Get.find<CategoryController>();
      final categories = categoryController.categories;
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoSection(),
        const SizedBox(height: 24),
        _buildScheduleSection(),
        const SizedBox(height: 24),
        _buildAccountSection(),
        const SizedBox(height: 32),
        _buildActionButtons(),
      ],
    );
  }
  
  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
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
                items: Get.find<CategoryController>().categories.map((category) {
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
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Planification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
              ExpenseDatePicker(
                selectedDate: selectedDate,
                frequency: selectedFrequency,
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compte',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: AppDropdownField<String>(
            value: selectedAccountId ?? '',
            label: 'Compte associé',
            icon: Icons.account_balance,
            items: widget.accounts.map((account) {
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
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppModalButton(
            label: 'Annuler',
            onPressed: widget.onCancel,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppModalButton(
            label: widget.expense == null ? 'Ajouter' : 'Enregistrer',
            isPrimary: true,
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  amountController.text.isNotEmpty &&
                  selectedAccountId != null) {
                final amount = double.tryParse(
                        amountController.text.replaceAll(',', '.')) ??
                    0.0;

                final expense = ExpenseModel(
                  id: widget.expense?.id ??
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
          ),
        ),
      ],
    );
  }
}
