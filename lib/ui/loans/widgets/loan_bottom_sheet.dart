import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/account_model.dart';

class LoanBottomSheet extends StatefulWidget {
  final List<AccountModel> accounts;
  final LoanModel? loan;
  final Function(LoanModel) onSubmit;
  final VoidCallback onCancel;

  const LoanBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.loan,
    super.key,
  });

  static void show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required Function(LoanModel) onSubmit,
    required VoidCallback onCancel,
    LoanModel? loan,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: loan == null ? 'Ajouter un emprunt' : 'Modifier l\'emprunt',
      child: LoanBottomSheet(
        accounts: accounts,
        onSubmit: onSubmit,
        onCancel: onCancel,
        loan: loan,
      ),
    );
  }

  @override
  State<LoanBottomSheet> createState() => _LoanBottomSheetState();
}

class _LoanBottomSheetState extends State<LoanBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _lenderController;
  late TextEditingController _monthlyPaymentController;
  late TextEditingController _dayOfMonthController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  int? _selectedAccountId;

  // Error states
  String? _nameError;
  String? _lenderError;
  String? _amountError;
  String? _monthlyError;
  String? _accountError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.loan?.name ?? '');
    _amountController = TextEditingController(
      text: widget.loan?.amount.toString() ?? '',
    );
    _lenderController = TextEditingController(
      text: widget.loan?.lenderName ?? '',
    );
    _monthlyPaymentController = TextEditingController(
      text: widget.loan?.monthlyPayment.toString() ?? '',
    );
    _dayOfMonthController = TextEditingController(
      text: widget.loan?.dayOfMonth.toString() ?? '1',
    );

    _startDate = widget.loan?.startDate ?? DateTime.now();
    _endDate =
        widget.loan?.endDate ?? DateTime.now().add(const Duration(days: 365));

    _startDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_startDate),
    );
    _endDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_endDate),
    );

    _selectedAccountId =
        widget.loan?.accountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);

    // Add listeners to clear errors
    _nameController.addListener(() => _clearError('name'));
    _lenderController.addListener(() => _clearError('lender'));
    _amountController.addListener(() => _clearError('amount'));
    _monthlyPaymentController.addListener(() => _clearError('monthly'));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _lenderController.dispose();
    _monthlyPaymentController.dispose();
    _dayOfMonthController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'name':
          _nameError = null;
          break;
        case 'lender':
          _lenderError = null;
          break;
        case 'amount':
          _amountError = null;
          break;
        case 'monthly':
          _monthlyError = null;
          break;
        case 'account':
          _accountError = null;
          break;
      }
    });
  }

  void _handleSubmit() {
    bool isValid = true;
    setState(() {
      if (_nameController.text.isEmpty) {
        _nameError = 'Le nom est requis';
        isValid = false;
      } else {
        _nameError = null;
      }
      if (_lenderController.text.isEmpty) {
        _lenderError = 'Le prêteur est requis';
        isValid = false;
      } else {
        _lenderError = null;
      }
      if (_amountController.text.isEmpty) {
        _amountError = 'Le montant est requis';
        isValid = false;
      } else {
        _amountError = null;
      }
      if (_monthlyPaymentController.text.isEmpty) {
        _monthlyError = 'La mensualité est requise';
        isValid = false;
      } else {
        _monthlyError = null;
      }
      if (_selectedAccountId == null) {
        _accountError = 'Le compte est requis';
        isValid = false;
      } else {
        _accountError = null;
      }
    });

    if (!isValid) return;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final monthlyPayment =
        double.tryParse(_monthlyPaymentController.text.replaceAll(',', '.')) ??
        0.0;
    final dayOfMonth = int.tryParse(_dayOfMonthController.text) ?? 1;

    _saveLoan(amount, monthlyPayment, dayOfMonth);
  }

  void _saveLoan(double amount, double monthlyPayment, int dayOfMonth) {
    final loan =
        widget.loan != null
            ? widget.loan!.copyWith(
              name: _nameController.text.trim(),
              amount: amount,
              accountId: _selectedAccountId!,
              startDate: _startDate,
              endDate: _endDate,
              lenderName: _lenderController.text.trim(),
              monthlyPayment: monthlyPayment,
              dayOfMonth: dayOfMonth,
            )
            : LoanModel(
              id: 0,
              name: _nameController.text.trim(),
              amount: amount,
              accountId: _selectedAccountId!,
              startDate: _startDate,
              endDate: _endDate,
              lenderName: _lenderController.text.trim(),
              monthlyPayment: monthlyPayment,
              dayOfMonth: dayOfMonth,
            );

    widget.onSubmit(loan);
    Navigator.pop(context);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);

          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 365));
            _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate);
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
    }
  }

  Widget _buildFieldWithValidation({required Widget child, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              errorText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
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
          _buildFieldWithValidation(
            errorText: _nameError,
            child: FrostedTextField(
              controller: _nameController,
              labelText: 'Nom',
              hintText: 'Ex: Prêt Immobilier',
              prefixIcon: const Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 16),
          _buildFieldWithValidation(
            errorText: _lenderError,
            child: FrostedTextField(
              controller: _lenderController,
              labelText: 'Prêteur',
              hintText: 'Ex: Banque Populaire',
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFieldWithValidation(
                  errorText: _amountError,
                  child: FrostedTextField(
                    controller: _amountController,
                    labelText: 'Montant total',
                    hintText: 'Ex: 250000',
                    prefixIcon: const Icon(Icons.euro),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFieldWithValidation(
                  errorText: _monthlyError,
                  child: FrostedTextField(
                    controller: _monthlyPaymentController,
                    labelText: 'Mensualité',
                    hintText: 'Ex: 1200.50',
                    prefixIcon: const Icon(Icons.payments),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            'Calendrier',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FrostedTextField(
                  controller: _startDateController,
                  labelText: 'Date de début',
                  prefixIcon: const Icon(Icons.calendar_today),
                  readOnly: true,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FrostedTextField(
                  controller: _endDateController,
                  labelText: 'Date de fin',
                  prefixIcon: const Icon(Icons.event),
                  readOnly: true,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FrostedTextField(
            controller: _dayOfMonthController,
            labelText: 'Jour du prélèvement (1-31)',
            hintText: 'Ex: 5',
            prefixIcon: const Icon(Icons.calendar_view_day),
            keyboardType: TextInputType.number,
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
          _buildFieldWithValidation(
            errorText: _accountError,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _accountError != null
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedAccountId,
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  items:
                      widget.accounts.map((account) {
                        return DropdownMenuItem<int>(
                          value: account.id,
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                account.name,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedAccountId = value;
                        _clearError('account');
                      });
                    }
                  },
                ),
              ),
            ),
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
                child: Text(widget.loan == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
