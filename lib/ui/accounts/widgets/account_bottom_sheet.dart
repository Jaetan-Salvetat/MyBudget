import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
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
    FrostedBottomSheet.show(
      context: context,
      title: account == null ? 'Ajouter un compte' : 'Modifier le compte',
      child: AccountBottomSheet(
        account: account,
        onSubmit: onSubmit,
        onCancel: onCancel,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FrostedTextField(
          controller: _nameController,
          labelText: 'Nom du compte',
          hintText: 'Ex: Compte Courant',
          prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
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
                return FrostedTextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onChanged: (value) {
                    _bankController.text = value;
                    _validateForm();
                  },
                  labelText: 'Nom de la banque',
                  hintText: 'Ex: Crédit Agricole',
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: () {
                      // Trigger autocomplete?
                      // Autocomplete doesn't expose a way to manually trigger open easily without a key or hack.
                      // For now, we keep the icon for visual consistency.
                    },
                  ),
                );
              },
              optionsViewBuilder: (
                BuildContext context,
                AutocompleteOnSelected<String> onSelected,
                Iterable<String> options,
              ) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Material(
                      color: Colors.transparent,
                      child: FrostedCard(
                        borderRadius: 12,
                        padding: EdgeInsets.zero,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: 200,
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            separatorBuilder:
                                (context, index) => FrostedDivider(
                                  height: 1,
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.1),
                                ),
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return FrostedListTile(
                                onTap: () => onSelected(option),
                                title: Text(option),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              );
                            },
                          ),
                        ),
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
            FrostedTextButton(
              onPressed: () {
                widget.onCancel();
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 16),
            FrostedFilledButton(
              onPressed: _isFormValid ? _handleSubmit : null,
              child: Text(widget.account == null ? 'Ajouter' : 'Enregistrer'),
            ),
          ],
        ),
      ],
    );
  }
}
