import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/loans/widgets/loan_bottom_sheet.dart';
import 'package:mybudget/ui/loans/widgets/loans_list.dart';

class LoansScreen extends StatelessWidget {
  final bool isNested;
  final String fabTag;

  const LoansScreen({
    this.isNested = false,
    this.fabTag = 'loans_fab',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        const SizedBox(height: 100),
        Expanded(child: const LoansList()),
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
              onPressed: () => _showAddLoanBottomSheet(context),
              tooltip: 'Ajouter un emprunt',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Emprunts'), elevation: 0),
      floatingActionButton: FloatingActionButton(
        heroTag: fabTag,
        onPressed: () => _showAddLoanBottomSheet(context),
        tooltip: 'Ajouter un emprunt',
        child: const Icon(Icons.add),
      ),
      body: content,
    );
  }

  void _showAddLoanBottomSheet(BuildContext context) {
    final accountViewModel = Provider.of<AccountViewModel>(
      context,
      listen: false,
    );
    final loanViewModel = Provider.of<LoanViewModel>(context, listen: false);

    if (accountViewModel.accounts.isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Aucun compte disponible'),
              content: const Text(
                'Vous devez d\'abord créer un compte avant d\'ajouter un emprunt.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    LoanBottomSheet.show(
      context: context,
      accounts: accountViewModel.accounts,
      onSubmit: (loan) {
        loanViewModel.addLoan(loan);
      },
      onCancel: () {},
    );
  }
}
