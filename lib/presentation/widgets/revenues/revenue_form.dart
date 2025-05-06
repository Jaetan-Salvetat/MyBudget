import 'package:flutter/material.dart';
import 'package:mybudget/data/models/revenue_model.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/domain/entities/revenue.dart';
import 'package:mybudget/presentation/widgets/common/app_text_field.dart';
import 'package:mybudget/presentation/widgets/common/app_dropdown_field.dart';
import 'package:mybudget/presentation/widgets/common/app_date_picker.dart';

class RevenueForm extends StatefulWidget {
  final List<Account> accounts;
  final Revenue? revenue;
  final Function(Revenue) onSubmit;
  final Function() onCancel;

  const RevenueForm({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.revenue,
    super.key,
  });

  @override
  State<RevenueForm> createState() => _RevenueFormState();
}

class _RevenueFormState extends State<RevenueForm> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  bool isRegular = true;
  DateTime selectedDate = DateTime.now();
  int? selectedAccountId;

  @override
  void initState() {
    super.initState();

    if (widget.revenue != null) {
      nameController.text = widget.revenue!.name;
      amountController.text = widget.revenue!.amount.toString();
      isRegular = widget.revenue!.isRegular;
      selectedDate = widget.revenue!.date;
      selectedAccountId = widget.revenue!.accountId;
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

  @override
  Widget build(BuildContext context) {
    if (widget.accounts.isEmpty) {
      return AlertDialog(
        title: const Text('Aucun compte disponible'),
        content: const Text(
          'Vous devez d\'abord créer un compte avant d\'ajouter un revenu.',
        ),
        actions: [
          TextButton(onPressed: widget.onCancel, child: const Text('OK')),
        ],
      );
    }

    return AlertDialog(
      title: Text(
        widget.revenue == null ? 'Ajouter un revenu' : 'Modifier le revenu',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            /*
            Material(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Revenu régulier'),
                    value: isRegular,
                    onChanged: (value) {
                      setState(() {
                        isRegular = value ?? true;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Les revenus réguliers sont comptabilisés chaque mois pour le calcul des soldes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            */
            const SizedBox(height: 16),
            AppDatePicker(
              selectedDate: selectedDate,
              label: 'Date',
              icon: Icons.calendar_today,
              onDateChanged: (date) {
                setState(() {
                  selectedDate = date;
                });
              },
            ),
            const SizedBox(height: 16),
            AppDropdownField<int>(
              value: selectedAccountId ?? 0,
              label: 'Compte',
              icon: Icons.account_balance,
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

              final revenue = widget.revenue != null
                ? (widget.revenue as RevenueModel).copyWith(
                    name: nameController.text,
                    amount: amount,
                    isRegular: isRegular,
                    date: selectedDate,
                    accountId: selectedAccountId!,
                  )
                : RevenueModel.create(
                    name: nameController.text,
                    amount: amount,
                    isRegular: isRegular,
                    date: selectedDate,
                    accountId: selectedAccountId!,
                  );

              widget.onSubmit(revenue);
            }
          },
          child: Text(widget.revenue == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }
}
