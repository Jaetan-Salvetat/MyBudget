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
  late FocusNode _bankFocusNode;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _bankController = TextEditingController(text: widget.account?.bank ?? '');
    _bankFocusNode = FocusNode();

    _validateForm();

    _nameController.addListener(_validateForm);
    _bankController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _bankFocusNode.dispose();
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
        FrostedAutocomplete<String>(
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
          textEditingController: _bankController,
          focusNode: _bankFocusNode,
          labelText: 'Nom de la banque',
          hintText: 'Ex: Crédit Agricole',
          prefixIcon: const Icon(Icons.account_balance_outlined),
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
