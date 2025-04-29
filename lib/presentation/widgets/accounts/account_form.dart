import 'package:flutter/material.dart';
import 'package:mybudget/domain/entities/account.dart';
import 'package:mybudget/presentation/widgets/common/app_text_field.dart';

class AccountForm extends StatefulWidget {
  final Account? account;
  final Function(String name, String bank) onSubmit;
  final Function() onCancel;

  const AccountForm({
    required this.onSubmit,
    required this.onCancel,
    this.account,
    super.key,
  });

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final nameController = TextEditingController();
  final bankController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.account != null) {
      nameController.text = widget.account!.name;
      bankController.text = widget.account!.bank;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.account == null ? 'Ajouter un compte' : 'Modifier le compte',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: nameController,
              label: 'Nom du compte',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: bankController,
              label: 'Banque',
              icon: Icons.account_balance_outlined,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isNotEmpty &&
                bankController.text.isNotEmpty) {
              widget.onSubmit(
                nameController.text.trim(),
                bankController.text.trim(),
              );
            }
          },
          child: Text(widget.account == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }
}
