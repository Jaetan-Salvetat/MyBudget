import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/accounts/widgets/account_list.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
 
 
 

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
     
     

    final content = Column(
      children: [
         
         
        const SizedBox(height: 100),
        Expanded(child: const AccountList()),
      ],
    );

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

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Comptes')),
      floatingActionButton: FloatingActionButton(
        heroTag: fabTag,
        onPressed: () => _showAddAccountDialog(context),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      body: content,
    );
  }

  void _showAddAccountDialog(BuildContext context) {
     
    final accountViewModel = Provider.of<AccountViewModel>(
      context,
      listen: false,
    );

    AccountBottomSheet.show(
      context: context,
      onSubmit: (name, bank) {
        if (name.isEmpty || bank.isEmpty) return;

        final account = AccountModel.create(name: name, bank: bank);
        accountViewModel.addAccount(account);
      },
      onCancel: () {},
    );
  }
}
