import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/empty_state.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/loans/screens/loan_details_screen.dart';
import 'package:mybudget/ui/loans/widgets/loan_card.dart';
import 'package:mybudget/ui/loans/screens/loan_creation_screen.dart';
import 'package:mybudget/ui/loans/widgets/loan_summary_card.dart';

class LoansList extends ConsumerWidget {
  const LoansList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(loanProvider)
        .when(
          loading: () => const Center(child: FrostedCircularProgress()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (loans) {
            final loanNotifier = ref.read(loanProvider.notifier);
            final accounts = ref.watch(accountProvider).value ?? [];

            final activeLoans = loanNotifier.getActiveLoans();
            final completedLoans = loanNotifier.getCompletedLoans();
            final isEmpty = loans.isEmpty;

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 16, 16, mainFlowBottomInset(context)),
              children: [
                _buildSummaryCard(context, ref),
                if (isEmpty) ...[
                  const SizedBox(height: 24),
                  _buildEmptyState(context, ref),
                ],
                if (activeLoans.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Actifs', activeLoans.length),
                  ...activeLoans.map(
                    (loan) => _buildLoanCard(context, loan, accounts, ref),
                  ),
                ],
                if (completedLoans.isNotEmpty) ...[
                  _buildSectionTitle(
                    context,
                    'Remboursés',
                    completedLoans.length,
                  ),
                  ...completedLoans.map(
                    (loan) => _buildLoanCard(context, loan, accounts, ref),
                  ),
                ],
              ],
            );
          },
        );
  }

  Widget _buildSectionTitle(BuildContext context, String title, int count) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.09 * 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref) {
    final totalActiveInitialAmount = ref
        .read(loanProvider.notifier)
        .getTotalActiveInitialAmount();
    final totalRemainingAmount = ref
        .read(loanProvider.notifier)
        .getTotalRemainingAmount();
    final totalMonthlyPayment = ref
        .read(loanProvider.notifier)
        .getTotalMonthlyPayments();
    final totalRemainingCost = ref
        .read(loanProvider.notifier)
        .getTotalRemainingCost();
    final activeLoanCount = ref
        .read(loanProvider.notifier)
        .getActiveLoans()
        .length;

    final progress = totalActiveInitialAmount == 0
        ? 0.0
        : (totalActiveInitialAmount - totalRemainingAmount) /
              totalActiveInitialAmount;

    return LoanSummaryCard(
      totalDebt: totalRemainingAmount,
      monthlyPayment: totalMonthlyPayment,
      progress: progress,
      activeLoanCount: activeLoanCount,
      remainingCost: totalRemainingCost,
    );
  }

  Widget _buildLoanCard(
    BuildContext context,
    Loan loan,
    List<AccountModel> accounts,
    WidgetRef ref,
  ) {
    final accountName = accounts.isEmpty
        ? 'Compte inconnu'
        : accounts
              .firstWhere(
                (a) => a.id == loan.accountId,
                orElse: () =>
                    AccountModel.create(name: 'Compte inconnu', bank: ''),
              )
              .name;

    return LoanCard(
      loan: loan,
      accountName: accountName,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoanDetailsScreen(loan: loan),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return EmptyState(
      message: 'Aucun emprunt enregistré',
      subMessage: 'Ajoutez vos emprunts pour suivre vos remboursements',
      icon: Symbols.payments_rounded,
      buttonText: 'Ajouter un emprunt',
      onPressed: () {
        final accounts = ref.read(accountProvider).value ?? [];
        if (accounts.isEmpty) {
          _showNoAccountDialog(context, 'un emprunt');
          return;
        }
        _openLoanForm(context, ref, accounts);
      },
    );
  }

  Future<void> _openLoanForm(
    BuildContext context,
    WidgetRef ref,
    List<AccountModel> accounts,
  ) async {
    final loan = await LoanCreationScreen.push(
      context: context,
      accounts: accounts,
    );
    if (loan == null) return;

    await ref.read(loanProvider.notifier).addLoan(loan);
  }

  void _showNoAccountDialog(BuildContext context, String action) {
    showFrostedDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FrostedDialog(
        title: 'Aucun compte disponible',
        body: Text(
          'Vous devez d\'abord créer un compte avant d\'ajouter $action.',
        ),
        actions: [
          FrostedButton.text(
            label: 'OK',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
