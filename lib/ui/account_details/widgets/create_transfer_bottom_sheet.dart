import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/common/frequency_date_section.dart';
import 'package:provider/provider.dart';

class CreateTransferBottomSheet extends StatefulWidget {
  const CreateTransferBottomSheet({super.key});

  @override
  State<CreateTransferBottomSheet> createState() =>
      _CreateTransferBottomSheetState();

  static void show(BuildContext context) {
    FrostedBottomSheet.show(
      context: context,
      child: const CreateTransferBottomSheet(),
    );
  }
}

class _CreateTransferBottomSheetState extends State<CreateTransferBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  int? _selectedSourceAccountId;
  int? _selectedDestinationAccountId;
  Frequency _selectedFrequency = Frequency.monthly;
  DateTime _selectedDate = DateTime.now();

  String? _nameError;
  String? _amountError;
  String? _sourceAccountError;
  String? _destinationAccountError;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsVM = context.watch<AccountViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: [
            Text(
              'Nouveau virement',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            FrostedTextField(
              controller: _nameController,
              labelText: 'Libellé',
              hintText: 'Ex: Épargne vacances',
              errorText: _nameError,
            ),
            const SizedBox(height: 16),

            FrostedTextField(
              controller: _amountController,
              labelText: 'Montant',
              hintText: '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixIcon: const Icon(Icons.euro, size: 16),
              errorText: _amountError,
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context, 'De'),
                      FrostedDropdown<int>(
                        value: _selectedSourceAccountId,
                        items:
                            accountsVM.accounts.map((account) {
                              return DropdownMenuItem<int>(
                                value: account.id,
                                child: Text(account.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSourceAccountId = value;
                            _sourceAccountError = null;
                          });
                        },
                        hint: 'Sélectionner',
                      ),
                      if (_sourceAccountError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            _sourceAccountError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 38.0,
                  ),
                  child: Icon(Icons.arrow_forward_rounded),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context, 'Vers'),
                      FrostedDropdown<int>(
                        value: _selectedDestinationAccountId,
                        items:
                            accountsVM.accounts.map((account) {
                              return DropdownMenuItem<int>(
                                value: account.id,
                                child: Text(account.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDestinationAccountId = value;
                            _destinationAccountError = null;
                          });
                        },
                        hint: 'Sélectionner',
                      ),
                      if (_destinationAccountError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            _destinationAccountError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            FrequencyDateSection(
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

            SizedBox(
              height: 50,
              child: FrostedFilledButton(
                onPressed: _validate,
                child: const Text('Créer le virement'),
              ),
            ),

            Padding(padding: MediaQuery.of(context).viewInsets),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  void _validate() {
    bool isValid = true;
    setState(() {
      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Le libellé est requis';
        isValid = false;
      } else {
        _nameError = null;
      }

      final amountText = _amountController.text.replaceAll(',', '.');
      final amount = double.tryParse(amountText);
      if (amountText.isEmpty) {
        _amountError = 'Le montant est requis';
        isValid = false;
      } else if (amount == null || amount <= 0) {
        _amountError = 'Montant invalide';
        isValid = false;
      } else {
        _amountError = null;
      }

      if (_selectedSourceAccountId == null) {
        _sourceAccountError = 'Requis';
        isValid = false;
      } else {
        _sourceAccountError = null;
      }

      if (_selectedDestinationAccountId == null) {
        _destinationAccountError = 'Requis';
        isValid = false;
      } else if (_selectedDestinationAccountId == _selectedSourceAccountId) {
        _destinationAccountError = 'Doit être différent';
        isValid = false;
      } else {
        _destinationAccountError = null;
      }
    });

    if (isValid) {
      final transfer = TransferModel.create(
        name: _nameController.text,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        sourceAccountId: _selectedSourceAccountId!,
        destinationAccountId: _selectedDestinationAccountId!,
        date: _selectedDate,
        frequencyString: _selectedFrequency.name,
      );
      context.read<AccountViewModel>().createTransfer(transfer);
      Navigator.pop(context);
    }
  }
}
