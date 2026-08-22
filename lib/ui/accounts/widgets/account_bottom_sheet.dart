import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
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
    showFrostedBottomSheet<void>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: account == null ? 'Ajouter un compte' : 'Modifier le compte',
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
          label: 'Nom du compte',
          hintText: 'Ex: Compte Courant',
          leadingIcon: Symbols.account_balance_wallet_rounded,
          autofocus: widget.account == null,
        ),
        const SizedBox(height: 16),
        FrostedAutocomplete(
          options: BanksList.frenchBanks,
          onSelected: (String selection) => _validateForm(),
          controller: _bankController,
          focusNode: _bankFocusNode,
          label: 'Nom de la banque',
          hintText: 'Ex: Crédit Agricole',
          leadingIcon: Symbols.account_balance_rounded,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FrostedButton.text(
              label: 'Annuler',
              onPressed: () {
                widget.onCancel();
                Navigator.pop(context);
              },
            ),
            const SizedBox(width: 16),
            FrostedButton.filled(
              label: widget.account == null ? 'Ajouter' : 'Enregistrer',
              onPressed: _isFormValid ? _handleSubmit : null,
            ),
          ],
        ),
      ],
    );
  }
}
