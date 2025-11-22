import 'package:flutter/material.dart';
import 'package:mybudget/ui/accounts/widgets/account_list.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [Expanded(child: AccountList())]);
  }
}
