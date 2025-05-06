import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/data/models/loan_model.dart';
import 'package:mybudget/presentation/widgets/common/app_text_field.dart';
import 'package:mybudget/presentation/widgets/common/app_dropdown_field.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';

class LoanBottomSheet extends StatefulWidget {
  final List<AccountModel> accounts;
  final LoanModel? loan;
  final Function(LoanModel) onSubmit;
  final Function() onCancel;

  const LoanBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.loan,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required Function(LoanModel) onSubmit,
    required Function() onCancel,
    LoanModel? loan,
  }) {
    if (accounts.isEmpty) {
      return showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Aucun compte disponible'),
              content: const Text(
                'Vous devez d\'abord créer un compte avant d\'ajouter un emprunt.',
              ),
              actions: [
                TextButton(onPressed: onCancel, child: const Text('OK')),
              ],
            ),
      );
    }

    return AppModalBottomSheet.show(
      context: context,
      title: loan == null ? 'Ajouter un emprunt' : 'Modifier l\'emprunt',
      content: LoanBottomSheet(
        accounts: accounts,
        onSubmit: onSubmit,
        onCancel: onCancel,
        loan: loan,
      ),
      actions: const [],
      isScrollable: true,
    );
  }

  @override
  State<LoanBottomSheet> createState() => _LoanBottomSheetState();
}

class _LoanBottomSheetState extends State<LoanBottomSheet> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final monthlyPaymentController = TextEditingController();
  final lenderController = TextEditingController();
  final notesController = TextEditingController();

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 365));
  int dayOfMonth = DateTime.now().day;
  int? selectedAccountId;

  String? nameError;
  String? amountError;
  String? monthlyPaymentError;
  String? lenderError;
  String? accountError;
  String? dayError;

  @override
  void initState() {
    super.initState();

    if (widget.loan != null) {
      nameController.text = widget.loan!.name;
      amountController.text = widget.loan!.amount.toString();
      monthlyPaymentController.text = widget.loan!.monthlyPayment.toString();
      lenderController.text = widget.loan!.lenderName;
      notesController.text = widget.loan!.notes ?? '';
      startDate = widget.loan!.startDate;
      endDate = widget.loan!.endDate;
      dayOfMonth = widget.loan!.dayOfMonth;
      selectedAccountId = widget.loan!.accountId;
    } else if (widget.accounts.isNotEmpty) {
      selectedAccountId = widget.accounts.first.id;
    }

    amountController.addListener(_updateMonthlyPayment);
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.removeListener(_updateMonthlyPayment);
    amountController.dispose();
    monthlyPaymentController.dispose();
    lenderController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _updateMonthlyPayment() {
    if (amountController.text.isEmpty) return;

    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    final start = DateTime(startDate.year, startDate.month, 1);
    final end = DateTime(endDate.year, endDate.month, 1);
    final durationMonths =
        (end.year - start.year) * 12 + end.month - start.month;

    if (durationMonths <= 0) return;

    final monthlyPayment = amount / durationMonths;

    setState(() {
      monthlyPaymentController.text = monthlyPayment.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: nameController,
          label: 'Nom de l\'emprunt',
          icon: Icons.description,
          errorText: nameError,
          onChanged:
              (_) => setState(() {
                if (nameError != null) nameError = null;
              }),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: amountController,
          label: 'Montant total',
          icon: Icons.euro,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: amountError,
          onChanged:
              (_) => setState(() {
                if (amountError != null) amountError = null;
              }),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: monthlyPaymentController,
          label: 'Mensualité (calculée automatiquement)',
          icon: Icons.calendar_view_month,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: monthlyPaymentError,
          onChanged:
              (_) => setState(() {
                if (monthlyPaymentError != null) monthlyPaymentError = null;
              }),
          suffixIcon: Icon(
            Icons.auto_awesome,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: lenderController,
          label: 'Prêteur',
          icon: Icons.person,
          errorText: lenderError,
          onChanged:
              (_) => setState(() {
                if (lenderError != null) lenderError = null;
              }),
        ),
        const SizedBox(height: 16),
        _buildDayOfMonthSelector(),
        const SizedBox(height: 16),
        _buildDateRangeSelector(context),
        const SizedBox(height: 16),
        _buildAccountSelector(),
        const SizedBox(height: 16),
        AppTextField(
          controller: notesController,
          label: 'Notes (optionnel)',
          icon: Icons.note,
          keyboardType: TextInputType.multiline,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Row(
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
                label: widget.loan == null ? 'Ajouter' : 'Enregistrer',
                isPrimary: true,
                onPressed: _validateAndSubmit,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayOfMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jour du mois pour l\'échéance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jour $dayOfMonth de chaque mois',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  thumbColor: Theme.of(context).colorScheme.primary,
                  overlayColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                ),
                child: Slider(
                  value: dayOfMonth.toDouble(),
                  min: 1,
                  max: 31,
                  divisions: 30,
                  label: dayOfMonth.toString(),
                  onChanged: (value) {
                    setState(() {
                      dayOfMonth = value.toInt();
                      if (dayError != null) dayError = null;
                    });
                  },
                ),
              ),
              if (dayError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dayError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Période du prêt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _selectStartDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date de début',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(startDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectEndDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date de fin',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(endDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compte associé',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: AppDropdownField<int>(
            value: selectedAccountId ?? 0,
            label: 'Sélectionnez un compte',
            icon: Icons.account_balance,
            errorText: accountError,
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
                  if (accountError != null) accountError = null;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != startDate) {
      setState(() {
        startDate = pickedDate;
        if (endDate.isBefore(startDate)) {
          endDate = startDate.add(const Duration(days: 30));
        }
      });
      _updateMonthlyPayment();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          endDate.isAfter(startDate)
              ? endDate
              : startDate.add(const Duration(days: 30)),
      firstDate: startDate,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != endDate) {
      setState(() {
        endDate = pickedDate;
      });
      _updateMonthlyPayment();
    }
  }

  void _validateAndSubmit() {
    bool isValid = true;

    setState(() {
      if (nameController.text.isEmpty) {
        nameError = 'Le nom de l\'emprunt est requis';
        isValid = false;
      }

      if (amountController.text.isEmpty) {
        amountError = 'Le montant est requis';
        isValid = false;
      } else {
        final amount = double.tryParse(
          amountController.text.replaceAll(',', '.'),
        );
        if (amount == null || amount <= 0) {
          amountError = 'Veuillez entrer un montant valide';
          isValid = false;
        }
      }

      if (monthlyPaymentController.text.isEmpty) {
        monthlyPaymentError = 'La mensualité est requise';
        isValid = false;
      } else {
        final monthlyPayment = double.tryParse(
          monthlyPaymentController.text.replaceAll(',', '.'),
        );
        if (monthlyPayment == null || monthlyPayment <= 0) {
          monthlyPaymentError = 'Veuillez entrer une mensualité valide';
          isValid = false;
        }
      }

      if (lenderController.text.isEmpty) {
        lenderError = 'Le nom du prêteur est requis';
        isValid = false;
      }

      if (selectedAccountId == null) {
        accountError = 'Veuillez sélectionner un compte';
        isValid = false;
      }

      if (dayOfMonth < 1 || dayOfMonth > 31) {
        dayError = 'Jour invalide';
        isValid = false;
      }
    });

    if (isValid) {
      final amount =
          double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
      final monthlyPayment =
          double.tryParse(monthlyPaymentController.text.replaceAll(',', '.')) ??
          0.0;

      final loan =
          widget.loan != null
              ? widget.loan!.copyWith(
                name: nameController.text.trim(),
                amount: amount,
                monthlyPayment: monthlyPayment,
                lenderName: lenderController.text.trim(),
                dayOfMonth: dayOfMonth,
                startDate: startDate,
                endDate: endDate,
                accountId: selectedAccountId!,
                notes:
                    notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
              )
              : LoanModel.create(
                name: nameController.text.trim(),
                amount: amount,
                monthlyPayment: monthlyPayment,
                lenderName: lenderController.text.trim(),
                dayOfMonth: dayOfMonth,
                startDate: startDate,
                endDate: endDate,
                accountId: selectedAccountId!,
                notes:
                    notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
              );

      widget.onSubmit(loan);
      Navigator.of(context).pop();
    }
  }
}
