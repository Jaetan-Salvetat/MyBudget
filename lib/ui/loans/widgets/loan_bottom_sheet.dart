import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: LoanBottomSheet(
              accounts: accounts,
              onSubmit: onSubmit,
              onCancel: onCancel,
              loan: loan,
            ),
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

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  int? _selectedAccountId;

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
    _selectedAccountId =
        widget.loan?.accountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _lenderController.dispose();
    _monthlyPaymentController.dispose();
    _dayOfMonthController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_nameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedAccountId == null ||
        _monthlyPaymentController.text.isEmpty) {
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    final monthlyPayment =
        double.tryParse(_monthlyPaymentController.text.replaceAll(',', '.')) ??
        0.0;
    final dayOfMonth = int.tryParse(_dayOfMonthController.text) ?? 1;

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

          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 365));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.loan == null ? 'Ajouter un emprunt' : 'Modifier l\'emprunt',
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
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          FrostedTextField(
            controller: _lenderController,
            labelText: 'Prêteur',
            prefixIcon: const Icon(Icons.person),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FrostedTextField(
                  controller: _amountController,
                  labelText: 'Montant total',
                  prefixIcon: const Icon(Icons.euro),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FrostedTextField(
                  controller: _monthlyPaymentController,
                  labelText: 'Mensualité',
                  prefixIcon: const Icon(Icons.payments),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
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
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de début',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      "${_startDate.day}/${_startDate.month}/${_startDate.year}",
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date de fin',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event),
                    ),
                    child: Text(
                      "${_endDate.day}/${_endDate.month}/${_endDate.year}",
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FrostedTextField(
            controller: _dayOfMonthController,
            labelText: 'Jour du prélèvement (1-31)',
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
          DropdownButtonFormField<int>(
            value: _selectedAccountId,
            decoration: const InputDecoration(
              labelText: 'Compte débité',
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
