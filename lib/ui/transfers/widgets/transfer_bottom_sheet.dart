import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/ui/common/expense_frequency_date_section.dart';

class TransferBottomSheet extends StatefulWidget {
  final List<AccountModel> accounts;
  final TransferModel? transfer;
  final Function(TransferModel) onSubmit;
  final VoidCallback onCancel;

  const TransferBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.transfer,
    super.key,
  });

  static void show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required Function(TransferModel) onSubmit,
    required VoidCallback onCancel,
    TransferModel? transfer,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: transfer == null ? 'Ajouter un virement' : 'Modifier le virement',
      child: TransferBottomSheet(
        accounts: accounts,
        onSubmit: onSubmit,
        onCancel: onCancel,
        transfer: transfer,
      ),
    );
  }

  @override
  State<TransferBottomSheet> createState() => _TransferBottomSheetState();
}

class _TransferBottomSheetState extends State<TransferBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  int? _selectedFromAccountId;
  int? _selectedToAccountId;
  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = 'Mensuel';
  String? _nameError;
  String? _fromAccountError;
  String? _toAccountError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.transfer?.name ?? '');
    _amountController = TextEditingController(
      text: widget.transfer?.amount.toString() ?? '',
    );

    _selectedFromAccountId =
        widget.transfer?.fromAccountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
    _selectedToAccountId = widget.transfer?.toAccountId;
    _selectedDate = widget.transfer?.date ?? DateTime.now();
    _selectedFrequency = widget.transfer?.frequency ?? 'Mensuel';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<AccountModel> get _availableDestinations =>
      widget.accounts
          .where((a) => a.id != _selectedFromAccountId)
          .toList();

  bool _validateFields() {
    bool isValid = true;
    setState(() {
      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Veuillez saisir un nom';
        isValid = false;
      } else {
        _nameError = null;
      }

      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      if (amount <= 0) {
        _amountError = 'Le montant doit être supérieur à 0';
        isValid = false;
      } else {
        _amountError = null;
      }

      if (_selectedFromAccountId == null) {
        _fromAccountError = 'Veuillez sélectionner un compte source';
        isValid = false;
      } else {
        _fromAccountError = null;
      }

      if (_selectedToAccountId == null) {
        _toAccountError = 'Veuillez sélectionner un compte destination';
        isValid = false;
      } else {
        _toAccountError = null;
      }

      if (_selectedFromAccountId != null &&
          _selectedToAccountId != null &&
          _selectedFromAccountId == _selectedToAccountId) {
        _toAccountError = 'Le compte destination doit être différent';
        isValid = false;
      }
    });
    return isValid;
  }

  Future<void> _handleSubmit() async {
    if (!_validateFields()) {
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    final transfer =
        widget.transfer != null
            ? widget.transfer!.copyWith(
              name: _nameController.text.trim(),
              amount: amount,
              fromAccountId: _selectedFromAccountId!,
              toAccountId: _selectedToAccountId!,
              date: _selectedDate,
              frequency: _selectedFrequency,
            )
            : TransferModel.create(
              name: _nameController.text.trim(),
              amount: amount,
              fromAccountId: _selectedFromAccountId!,
              toAccountId: _selectedToAccountId!,
              date: _selectedDate,
              frequency: _selectedFrequency,
            );

    widget.onSubmit(transfer);
    Navigator.pop(context);
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
            FrostedTextField(
              controller: _nameController,
              labelText: 'Nom',
              hintText: 'Ex: Épargne mensuelle',
              prefixIcon: const Icon(Icons.edit),
            ),
            if (_nameError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                child: Text(
                  _nameError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
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

            const SizedBox(height: 24),

            Text(
              'Comptes',
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
                  'Compte source',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                FrostedDropdown<int>(
                  value: _selectedFromAccountId,
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
                        _selectedFromAccountId = value;
                        _fromAccountError = null;
                        if (_selectedToAccountId == value) {
                          _selectedToAccountId = null;
                        }
                      });
                    }
                  },
                ),
                if (_fromAccountError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Text(
                      _fromAccountError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compte destination',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                FrostedDropdown<int>(
                  value: _selectedToAccountId,
                  items:
                      _availableDestinations.map((account) {
                        return DropdownMenuItem<int>(
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedToAccountId = value;
                        _toAccountError = null;
                      });
                    }
                  },
                ),
                if (_toAccountError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Text(
                      _toAccountError!,
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
                  child: Text(
                    widget.transfer == null ? 'Ajouter' : 'Enregistrer',
                  ),
                ),
              ],
            ),
          ],
      ),
    );
  }
}
