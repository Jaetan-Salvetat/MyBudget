import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/account_details/screens/account_details_screen.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
import 'package:mybudget/ui/accounts/widgets/account_card.dart';
import 'package:mybudget/ui/accounts/widgets/add_account_tile.dart';
import 'package:mybudget/ui/common/empty_state.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/transfers/transfers_provider.dart';

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
                  icon: Icons.account_balance_wallet_outlined,
                  buttonText: 'Ajouter un compte',
                  onPressed: () => _showAddAccountDialog(context, ref),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 145),
              itemCount: accounts.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == accounts.length) {
                  return AddAccountTile(
                    onTap: () => _showAddAccountDialog(context, ref),
                  );
                }
                final account = accounts[index];
                final summary = _computeMonthSummary(ref, account.id);
                return AccountCard(
                  account: account,
                  monthlyIncomes: summary.incomes,
                  monthlyCharges: summary.charges,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AccountDetailsScreen(account: account),
                      settings: RouteSettings(arguments: account),
                    ),
                  ),
                );
              },
            );
          },
        );
  }

  _AccountMonthSummary _computeMonthSummary(WidgetRef ref, int accountId) {
    final accountExpenses = ref
        .read(expenseProvider.notifier)
        .getExpensesForAccount(accountId)
        .where((e) => e.endDate == null)
        .toList();
    final now = DateTime.now();
    final currentMonthExpenses = accountExpenses
        .where((e) =>
            e.frequencyEnum == Frequency.monthly ||
            (e.frequencyEnum == Frequency.annual &&
                e.startDate.month == now.month))
        .fold(0.0, (double sum, e) => sum + e.amount);

    final monthlyRevenues = ref
        .read(revenueProvider.notifier)
        .getRevenuesForAccount(accountId)
        .where((r) => r.endDate == null)
        .fold(0.0, (double sum, r) => sum + r.amount);

    final transferNotifier = ref.read(transferProvider.notifier);
    final outgoingTransfers =
        transferNotifier.getOutgoingTotalForAccount(accountId);
    final incomingTransfers =
        transferNotifier.getIncomingTotalForAccount(accountId);

    return _AccountMonthSummary(
      incomes: monthlyRevenues + incomingTransfers,
      charges: currentMonthExpenses + outgoingTransfers,
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

class _AccountMonthSummary {
  final double incomes;
  final double charges;

  const _AccountMonthSummary({required this.incomes, required this.charges});
}
