import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/presentation/widgets/accounts/account_list.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';
import 'package:mybudget/presentation/widgets/accounts/account_bottom_sheet.dart';

class AccountsScreen extends StatelessWidget {
  final bool isNested;
  final String fabTag;

  const AccountsScreen({
    this.isNested = false,
    this.fabTag = 'accounts_fab',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const content = Column(children: [SizedBox(height: 100), AccountsList()]);

    if (isNested) {
      return Stack(
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: fabTag,
              onPressed: () => _showAddAccountDialog(context),
              elevation: 4,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return AppScaffold(
      title: 'Mes Comptes',
      floatingActionButton: FloatingActionButton(
        heroTag: fabTag,
        onPressed: () => _showAddAccountDialog(context),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      child: content,
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final accountController = Get.find<AccountController>();

    AccountBottomSheet.show(
      context: context,
      onSubmit: (name, bank) {
        if (name.isEmpty || bank.isEmpty) return;

        final account = AccountModel.create(name: name, bank: bank);

        accountController.addAccount(account);
      },
      onCancel: () {},
    );
  }
}
