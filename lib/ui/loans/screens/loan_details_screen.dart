import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/loans/widgets/loan_bottom_sheet.dart';
import 'package:mybudget/ui/loans/widgets/loan_header.dart';
import 'package:mybudget/ui/loans/widgets/loan_progress_section.dart';
import 'package:mybudget/ui/loans/widgets/loan_details_section.dart';

class LoanDetailsScreen extends StatefulWidget {
  final LoanModel loan;

  const LoanDetailsScreen({required this.loan, super.key});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  late LoanModel loan;

  final formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    loan = widget.loan;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoanViewModel, AccountViewModel>(
      builder: (context, loanVM, accountVM, child) {
        final exists = loanVM.loans.any((l) => l.id == loan.id);
        if (!exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final updatedLoan = loanVM.loans.firstWhere((l) => l.id == loan.id);
        
        final accountName = accountVM.accounts.isEmpty
            ? 'Compte inconnu'
            : accountVM.accounts.firstWhere(
                (a) => a.id == updatedLoan.accountId,
                orElse: () => AccountModel.create(name: 'Compte inconnu', bank: ''),
              ).name;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Détails de l\'emprunt'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditLoanBottomSheet(context, updatedLoan, accountVM.accounts, loanVM),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmation(context, updatedLoan, loanVM),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoanHeader(loan: updatedLoan, accountName: accountName),
                const SizedBox(height: 24),
                LoanProgressSection(loan: updatedLoan, formatter: formatter),
                const SizedBox(height: 24),
                LoanDetailsSection(loan: updatedLoan),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditLoanBottomSheet(
    BuildContext context, 
    LoanModel loan, 
    List<AccountModel> accounts,
    LoanViewModel loanVM
  ) {
    LoanBottomSheet.show(
      context: context,
      accounts: accounts,
      loan: loan,
      onSubmit: (updatedLoan) {
        loanVM.updateLoan(updatedLoan);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emprunt mis à jour')),
        );
      },
      onCancel: () {},
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    LoanModel loan,
    LoanViewModel loanVM
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet emprunt ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              loanVM.deleteLoan(loan.id);
              Navigator.pop(context); 
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
