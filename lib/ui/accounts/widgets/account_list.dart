import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/account_details/screens/account_details_screen.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/accounts/screens/account_form_screen.dart';
import 'package:mybudget/ui/accounts/widgets/account_card.dart';
import 'package:mybudget/ui/accounts/widgets/add_account_tile.dart';
import 'package:mybudget/ui/common/empty_state.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/transfers/transfers_provider.dart';

class AccountList extends ConsumerWidget {
  const AccountList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(accountProvider)
        .when(
          loading: () => const Center(child: FrostedCircularProgress()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (accounts) {
            if (accounts.isEmpty) {
              return Center(
                child: EmptyState(
                  message: 'Aucun compte',
                  subMessage: 'Ajoutez un compte pour commencer',
                  icon: Symbols.account_balance_wallet_rounded,
                  buttonText: 'Ajouter un compte',
                  onPressed: () => _openAccountForm(context, ref),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final account in accounts) ...[
                  _AccountCardEntry(account: account),
                  const SizedBox(height: 12),
                ],
                AddAccountTile(
                  onTap: () => _openAccountForm(context, ref),
                ),
              ],
            );
          },
        );
  }

  Future<void> _openAccountForm(BuildContext context, WidgetRef ref) async {
    final account = await AccountFormScreen.push(context: context);
    if (account == null || !context.mounted) return;

    try {
      await ref.read(accountProvider.notifier).addAccount(account);
    } catch (e) {
      if (context.mounted) {
        FrostedSnackbar.show(context, message: 'Erreur lors de l\'ajout: $e');
      }
    }
  }
}

class _AccountCardEntry extends ConsumerWidget {
  final AccountModel account;

  const _AccountCardEntry({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(monthExpensesProvider);
    final revenues = ref.watch(monthRevenuesProvider);

    final monthlyLoanPayments = ref
        .watch(loanProvider.notifier)
        .getTotalMonthlyPaymentsForAccount(account.id);

    final transferNotifier = ref.watch(transferProvider.notifier);
    final outgoingTransfers = transferNotifier.getOutgoingTotalForAccount(
      account.id,
    );
    final incomingTransfers = transferNotifier.getIncomingTotalForAccount(
      account.id,
    );

    final totalExpenses = expenses
        .where((expense) => expense.accountId == account.id)
        .fold(0.0, (sum, expense) => sum + expense.amount);

    final totalRevenues = revenues
        .where((revenue) => revenue.accountId == account.id)
        .fold(0.0, (sum, revenue) => sum + revenue.amount);

    final charges = totalExpenses + monthlyLoanPayments + outgoingTransfers;
    final incomes = totalRevenues + incomingTransfers;

    return AccountCard(
      account: account,
      monthlyIncomes: incomes,
      monthlyCharges: charges,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccountDetailsScreen(account: account),
          settings: RouteSettings(arguments: account),
        ),
      ),
    );
  }
}
