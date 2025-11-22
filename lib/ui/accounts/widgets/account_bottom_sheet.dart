import 'package:flutter/material.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/core/constants/banks_list.dart';

class AccountBottomSheet extends StatefulWidget {
  final AccountModel? account;
  final Function(String name, String bank) onSubmit;
  final VoidCallback onCancel;

  const AccountBottomSheet({
    this.account,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  static void show({
    required BuildContext context,
    AccountModel? account,
    required Function(String name, String bank) onSubmit,
    required VoidCallback onCancel,
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
            child: AccountBottomSheet(
              account: account,
              onSubmit: onSubmit,
              onCancel: onCancel,
            ),
          ),
    );
  }

  @override
  State<AccountBottomSheet> createState() => _AccountBottomSheetState();
}

class _AccountBottomSheetState extends State<AccountBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bankController;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _bankController = TextEditingController(text: widget.account?.bank ?? '');

     
    _validateForm();

    _nameController.addListener(_validateForm);
    _bankController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid =
        _nameController.text.trim().isNotEmpty &&
        _bankController.text.trim().isNotEmpty;
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _handleSubmit() {
    if (_isFormValid) {
      widget.onSubmit(_nameController.text.trim(), _bankController.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.account == null ? 'Ajouter un compte' : 'Modifier le compte',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom du compte',
              hintText: 'Ex: Compte Courant',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: widget.account == null,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Autocomplete<String>(
                initialValue: TextEditingValue(text: _bankController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return BanksList.frenchBanks.take(5);
                  }
                  return BanksList.frenchBanks.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  _bankController.text = selection;
                  _validateForm();
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                   
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onChanged: (value) {
                      _bankController.text = value;
                      _validateForm();
                    },
                    decoration: InputDecoration(
                      labelText: 'Nom de la banque',
                      hintText: 'Ex: Crédit Agricole',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_drop_down),
                        onPressed: () {
                           
                           
                           
                        },
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  );
                },
                optionsViewBuilder: (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: constraints.maxWidth,
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
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
                onPressed: _isFormValid ? _handleSubmit : null,
                child: Text(widget.account == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
