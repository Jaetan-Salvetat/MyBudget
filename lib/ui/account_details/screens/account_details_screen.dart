import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/utils/history_utils.dart';
import 'package:mybudget/core/entities/transfer.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/transfers/transfers_provider.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
import 'package:mybudget/ui/transfers/widgets/transfer_bottom_sheet.dart';
import 'package:mybudget/ui/account_details/widgets/account_hero_card.dart';
import 'package:mybudget/ui/account_details/widgets/account_balance_breakdown.dart';
import 'package:mybudget/ui/common/widgets/transfer_card.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  final AccountModel account;

  const AccountDetailsScreen({required this.account, super.key});

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  late AccountModel account;

  final formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    account = widget.account;
  }

  @override
  Widget build(BuildContext context) {
    final balance =
        ref.watch(accountProvider.notifier).getAccountBalance(account.id);

    final selectedMonth = ref.watch(selectedMonthProvider);
    final expenses = ref.watch(expenseProvider).value ?? [];
    final revenues = ref.watch(revenueProvider).value ?? [];
    final loans = ref.watch(loanProvider).value ?? [];

    double totalRevenues = 0.0;
    for (final revenue in revenues.where((r) => r.accountId == account.id)) {
      if (!isActiveForMonth(revenue.startDate, revenue.endDate, selectedMonth)) continue;
      switch (revenue.frequencyEnum) {
        case Frequency.monthly:
          totalRevenues += revenue.amount;
        case Frequency.annual:
          if (revenue.startDate.month == selectedMonth.month) {
            totalRevenues += revenue.amount;
          }
        case Frequency.oneTime:
          if (revenue.startDate.year == selectedMonth.year &&
              revenue.startDate.month == selectedMonth.month) {
            totalRevenues += revenue.amount;
          }
      }
    }

    double totalExpenses = 0.0;
    for (final expense in expenses.where((e) => e.accountId == account.id)) {
      if (!isActiveForMonth(expense.startDate, expense.endDate, selectedMonth)) continue;
      switch (expense.frequencyEnum) {
        case Frequency.monthly:
          totalExpenses += expense.amount;
        case Frequency.annual:
          if (expense.startDate.month == selectedMonth.month) {
            totalExpenses += expense.amount;
          }
        case Frequency.oneTime:
          if (expense.startDate.year == selectedMonth.year &&
              expense.startDate.month == selectedMonth.month) {
            totalExpenses += expense.amount;
          }
      }
    }

    final totalLoanPayments = loans
        .where((l) => l.accountId == account.id && !l.isCompleted)
        .fold(0.0, (sum, loan) => sum + loan.currentMonthlyPayment);

    final transferNotifier = ref.watch(transferProvider.notifier);
    final totalTransfers = transferNotifier.getMonthlyTransferBalance(account.id);
    final transfers = transferNotifier.getActiveTransfersForAccount(account.id);
    final accounts = ref.watch(accountProvider).value ?? [];

    return FrostedScaffold(
      appBar: FrostedAppBar(
        title: 'Détails du compte',
        actions: [
          FrostedIconButton(
            icon: Icons.edit,
            onPressed: () => _showEditAccountBottomSheet(context),
          ),
          FrostedIconButton(
            icon: Icons.delete,
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      floatingActionButton: FrostedFloatingActionButton(
        onPressed: () => _showAddTransferBottomSheet(context),
        child: const Icon(Icons.swap_horiz),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 100),
            AccountHeroCard(
              account: account,
              balance: balance,
              totalRevenues: totalRevenues,
              totalExpenses: totalExpenses + totalLoanPayments,
              totalTransfers: totalTransfers,
              formatter: formatter,
            ),
            const SizedBox(height: 24),
            AccountBalanceBreakdown(
              totalRevenues: totalRevenues,
              totalExpenses: totalExpenses,
              totalLoanPayments: totalLoanPayments,
              totalTransfers: totalTransfers,
              balance: balance,
              formatter: formatter,
            ),
            const SizedBox(height: 24),
            _buildTransferSection(context, transfers, accounts),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferSection(
    BuildContext context,
    List<Transfer> transfers,
    List<AccountModel> accounts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Virements',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (transfers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun virement',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...transfers.map(
            (transfer) => TransferCard(
              transfer: transfer,
              currentAccountId: account.id,
              otherAccountName: _getOtherAccountName(transfer, accounts),
              onEdit: () => _showEditTransferBottomSheet(context, transfer),
              onDelete: () => _deleteTransfer(transfer.id),
            ),
          ),
      ],
    );
  }

  String _getOtherAccountName(Transfer transfer, List<AccountModel> accounts) {
    final otherAccountId = transfer.isOutgoingFrom(account.id)
        ? transfer.toAccountId
        : transfer.fromAccountId;
    final otherAccount = accounts.where((a) => a.id == otherAccountId).firstOrNull;
    return otherAccount?.name ?? 'Compte inconnu';
  }

  void _showEditAccountBottomSheet(BuildContext context) {
    AccountBottomSheet.show(
      context: context,
      account: account,
      onSubmit: (name, bank) async {
        try {
          final updatedAccount = account.copyWith(name: name, bank: bank);
          await ref.read(accountProvider.notifier).updateAccount(updatedAccount);
          setState(() {
            account = updatedAccount;
          });
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(context, message: 'Erreur lors de la modification: \$e');
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showAddTransferBottomSheet(BuildContext context) {
    final accounts = ref.read(accountProvider).value ?? [];
    TransferBottomSheet.show(
      context: context,
      accounts: accounts,
      closedTransfers: ref.read(transferProvider.notifier).getClosedTransfers(),
      onSubmit: (transfer) async {
        try {
          await ref.read(transferProvider.notifier).addTransfer(transfer);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(context, message: 'Erreur lors de l\'ajout du virement: $e');
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showEditTransferBottomSheet(BuildContext context, Transfer transfer) {
    final accounts = ref.read(accountProvider).value ?? [];
    TransferBottomSheet.show(
      context: context,
      accounts: accounts,
      transfer: transfer.model,
      onSubmit: (updatedTransfer) async {
        try {
          await ref.read(transferProvider.notifier).updateTransfer(updatedTransfer);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(context, message: 'Erreur lors de la modification du virement: $e');
          }
        }
      },
      onCancel: () {},
    );
  }

  Future<void> _deleteTransfer(int id) async {
    try {
      await ref.read(transferProvider.notifier).deleteTransfer(id);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(context, message: 'Erreur lors de la suppression du virement: $e');
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final linkedExpenses = ref.read(expenseProvider.notifier).getExpensesForAccount(account.id);
    final linkedRevenues = ref.read(revenueProvider.notifier).getRevenuesForAccount(account.id);
    final linkedLoans = ref.read(loanProvider.notifier).getActiveLoansForAccount(account.id);
    final linkedTransfers = ref.read(transferProvider.notifier).getTransfersForAccount(account.id);

    final totalLinked = linkedExpenses.length + linkedRevenues.length + linkedLoans.length + linkedTransfers.length;

    if (totalLinked > 0) {
      final parts = <String>[];
      if (linkedExpenses.isNotEmpty) {
        parts.add('${linkedExpenses.length} dépense${linkedExpenses.length > 1 ? 's' : ''}');
      }
      if (linkedRevenues.isNotEmpty) {
        parts.add('${linkedRevenues.length} revenu${linkedRevenues.length > 1 ? 's' : ''}');
      }
      if (linkedLoans.isNotEmpty) {
        parts.add('${linkedLoans.length} emprunt${linkedLoans.length > 1 ? 's' : ''}');
      }
      if (linkedTransfers.isNotEmpty) {
        parts.add('${linkedTransfers.length} virement${linkedTransfers.length > 1 ? 's' : ''}');
      }

      FrostedDialog.show(
        context: context,
        title: const Text('Suppression impossible'),
        content: Text(
          '${parts.join(', ')} ${totalLinked > 1 ? 'sont associés' : 'est associé(e)'} à "${account.name}". Réassignez-les avant de supprimer ce compte.',
        ),
        actions: [
          FrostedFilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      );
      return;
    }

    FrostedDialog.show(
      context: context,
      title: const Text('Confirmer la suppression'),
      content: Text(
        'Voulez-vous vraiment supprimer le compte ${account.name} ?',
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FrostedTextButton(
          onPressed: () async {
            try {
              await ref.read(accountProvider.notifier).deleteAccount(account.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.of(context).pop();
                FrostedSnackbar.show(context, message: 'Erreur lors de la suppression: \$e');
              }
            }
          },
          child: Text(
            'Supprimer',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
