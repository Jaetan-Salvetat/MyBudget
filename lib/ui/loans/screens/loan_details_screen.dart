import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/domain/loan.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/loans/widgets/loan_header.dart';
import 'package:mybudget/ui/loans/widgets/loan_progress_section.dart';
import 'package:mybudget/ui/loans/widgets/loan_details_section.dart';
import 'package:mybudget/ui/loans/widgets/loan_edit_bottom_sheet.dart';

class LoanDetailsScreen extends StatefulWidget {
  final Loan loan;

  const LoanDetailsScreen({required this.loan, super.key});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  late Loan loan;

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
          return const FrostedScaffold(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final updatedLoan = loanVM.loans.firstWhere((l) => l.id == loan.id);

        final accountName =
            accountVM.accounts.isEmpty
                ? 'Compte inconnu'
                : accountVM.accounts
                    .firstWhere(
                      (a) => a.id == updatedLoan.accountId,
                      orElse:
                          () => AccountModel.create(
                            name: 'Compte inconnu',
                            bank: '',
                          ),
                    )
                    .name;

        return FrostedScaffold(
          appBar: FrostedAppBar(
            title: 'Détails de l\'emprunt',
            actions: [
              FrostedIconButton(
                icon: Icons.edit,
                onPressed:
                    () => _showEditLoanBottomSheet(
                      context,
                      updatedLoan,
                      accountVM.accounts,
                      loanVM,
                    ),
              ),
              FrostedIconButton(
                icon: Icons.delete,
                onPressed:
                    () => _showDeleteConfirmation(context, updatedLoan, loanVM),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              top: 120,
              left: 16,
              right: 16,
              bottom: 16,
            ),
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
    Loan loan,
    List<AccountModel> accounts,
    LoanViewModel loanVM,
  ) {
    LoanEditBottomSheet.show(
      context: context,
      loan: loan,
      accounts: accounts,
      onSubmit: (updatedLoanModel) {
        loanVM.updateLoan(updatedLoanModel);
        FrostedSnackbar.show(
          context,
          message: 'Emprunt mis à jour avec succès',
        );
      },
      onCancel: () {},
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Loan loan,
    LoanViewModel loanVM,
  ) {
    FrostedDialog.show(
      context: context,
      title: const Text('Confirmer la suppression'),
      content: const Text(
        'Êtes-vous sûr de vouloir supprimer cet emprunt ? Cette action est irréversible.',
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FrostedTextButton(
          foregroundColor: Theme.of(context).colorScheme.error,
          onPressed: () {
            loanVM.deleteLoan(loan.id);
            Navigator.pop(context);
          },
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
