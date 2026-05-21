import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/account_details/screens/account_details_screen.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
import 'package:mybudget/ui/accounts/widgets/account_card.dart';
import 'package:mybudget/ui/accounts/widgets/add_account_tile.dart';
import 'package:mybudget/ui/common/empty_state.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/transfers/transfers_provider.dart';
import 'package:mybudget/utils/history_utils.dart';

class AccountList extends ConsumerWidget {
  const AccountList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(accountProvider)
        .when(
          loading: () =>
              const Center(child: FrostedCircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (accounts) {
            if (accounts.isEmpty) {
              return Center(
                child: EmptyState(
                  message: 'Aucun compte',
                  subMessage: 'Ajoutez un compte pour commencer',
                  icon: Symbols.account_balance_wallet_rounded,
                  buttonText: 'Ajouter un compte',
                  onPressed: () => _showAddAccountDialog(context, ref),
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
                  onTap: () => _showAddAccountDialog(context, ref),
                ),
              ],
            );
          },
        );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    AccountBottomSheet.show(
      context: context,
      onSubmit: (name, bank) async {
        if (name.isEmpty || bank.isEmpty) return;

        try {
          final account = AccountModel.create(name: name, bank: bank);
          await ref.read(accountProvider.notifier).addAccount(account);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de l\'ajout: $e',
            );
          }
        }
      },
      onCancel: () {},
    );
  }
}

class _AccountCardEntry extends ConsumerWidget {
  final AccountModel account;

  const _AccountCardEntry({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final expenses = ref.watch(expenseProvider).value ?? [];
    final revenues = ref.watch(revenueProvider).value ?? [];

    final monthlyLoanPayments = ref
        .watch(loanProvider.notifier)
        .getTotalMonthlyPaymentsForAccount(account.id);

    final transferNotifier = ref.watch(transferProvider.notifier);
    final outgoingTransfers =
        transferNotifier.getOutgoingTotalForAccount(account.id);
    final incomingTransfers =
        transferNotifier.getIncomingTotalForAccount(account.id);

    final totalExpenses = expenses
        .where((e) => e.accountId == account.id)
        .where((e) => isActiveForMonth(e.startDate, e.endDate, selectedMonth))
        .fold(0.0, (sum, e) => sum + _amountIfApplicable(e, selectedMonth));

    final totalRevenues = revenues
        .where((r) => r.accountId == account.id)
        .where((r) => isActiveForMonth(r.startDate, r.endDate, selectedMonth))
        .fold(0.0, (sum, r) => sum + _revenueAmountIfApplicable(r, selectedMonth));

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

  double _amountIfApplicable(ExpenseModel e, DateTime selectedMonth) {
    switch (e.frequencyEnum) {
      case Frequency.monthly:
        return e.amount;
      case Frequency.annual:
        return e.startDate.month == selectedMonth.month ? e.amount : 0;
      case Frequency.oneTime:
        return e.startDate.year == selectedMonth.year &&
                e.startDate.month == selectedMonth.month
            ? e.amount
            : 0;
    }
  }

  double _revenueAmountIfApplicable(RevenueModel r, DateTime selectedMonth) {
    switch (r.frequencyEnum) {
      case Frequency.monthly:
        return r.amount;
      case Frequency.annual:
        return r.startDate.month == selectedMonth.month ? r.amount : 0;
      case Frequency.oneTime:
        return r.startDate.year == selectedMonth.year &&
                r.startDate.month == selectedMonth.month
            ? r.amount
            : 0;
    }
  }
}
