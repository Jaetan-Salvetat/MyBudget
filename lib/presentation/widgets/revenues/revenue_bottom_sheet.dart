import 'package:flutter/material.dart';
import 'package:mybudget/data/models/revenue_model.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/presentation/widgets/common/app_text_field.dart';
import 'package:mybudget/presentation/widgets/common/app_dropdown_field.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/revenues/revenue_date_picker.dart';

class RevenueBottomSheet extends StatefulWidget {
  final List<AccountModel> accounts;
  final RevenueModel? revenue;
  final Function(RevenueModel) onSubmit;
  final Function() onCancel;

  const RevenueBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.revenue,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required Function(RevenueModel) onSubmit,
    required Function() onCancel,
    RevenueModel? revenue,
  }) {
    if (accounts.isEmpty) {
      return showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Aucun compte disponible'),
              content: const Text(
                'Vous devez d\'abord créer un compte avant d\'ajouter un revenu.',
              ),
              actions: [
                TextButton(onPressed: onCancel, child: const Text('OK')),
              ],
            ),
      );
    }

    return AppModalBottomSheet.show(
      context: context,
      title: revenue == null ? 'Ajouter un revenu' : 'Modifier le revenu',
      content: RevenueBottomSheet(
        accounts: accounts,
        onSubmit: onSubmit,
        onCancel: onCancel,
        revenue: revenue,
      ),
      actions: const [],
      isScrollable: true,
    );
  }

  @override
  State<RevenueBottomSheet> createState() => _RevenueBottomSheetState();
}

class _RevenueBottomSheetState extends State<RevenueBottomSheet> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  bool isRegular = true;
  DateTime selectedDate = DateTime.now();
  String? selectedAccountId;

  @override
  void initState() {
    super.initState();

    if (widget.revenue != null) {
      nameController.text = widget.revenue!.name;
      amountController.text = widget.revenue!.amount.toString();
      isRegular = widget.revenue!.isRegular;
      selectedDate = widget.revenue!.date;
      selectedAccountId = widget.revenue!.accountId.toString();
    } else if (widget.accounts.isNotEmpty) {
      selectedAccountId = widget.accounts.first.id.toString();
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
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
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
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /*SwitchListTile(
                title: const Text('Revenu régulier'),
                subtitle: const Text(
                  'Comptabilisé chaque mois pour le calcul des soldes',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                value: isRegular,
                onChanged: (value) {
                  setState(() {
                    isRegular = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),*/
              const SizedBox(height: 16),
              RevenueDatePicker(
                selectedDate: selectedDate,
                isRegularRevenue: isRegular,
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
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: AppDropdownField<String>(
            value: selectedAccountId ?? '',
            label: 'Compte associé',
            icon: Icons.account_balance,
            items:
                widget.accounts.map((account) {
                  return DropdownMenuItem(
                    value: account.id.toString(),
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
          child: AppModalButton(label: 'Annuler', onPressed: widget.onCancel),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppModalButton(
            label: widget.revenue == null ? 'Ajouter' : 'Enregistrer',
            isPrimary: true,
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  amountController.text.isNotEmpty &&
                  selectedAccountId != null) {
                final amount =
                    double.tryParse(
                      amountController.text.replaceAll(',', '.'),
                    ) ??
                    0.0;

                final revenue = widget.revenue != null
                  ? widget.revenue!.copyWith(
                      name: nameController.text,
                      amount: amount,
                      isRegular: isRegular,
                      date: selectedDate,
                      accountId: int.parse(selectedAccountId!),
                    )
                  : RevenueModel.create(
                      name: nameController.text,
                      amount: amount,
                      isRegular: isRegular,
                      date: selectedDate,
                      accountId: int.parse(selectedAccountId!),
                    );

                widget.onSubmit(revenue);
              }
            },
          ),
        ),
      ],
    );
  }
}
