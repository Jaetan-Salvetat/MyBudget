import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/entities/transfer.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/providers/selected_month_provider.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/account_details/widgets/account_balance_breakdown.dart';
import 'package:mybudget/ui/account_details/widgets/account_hero_card.dart';
import 'package:mybudget/ui/account_details/widgets/transfer_row.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
import 'package:mybudget/ui/common/widgets/app_top_bar.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/transfers/transfers_provider.dart';
import 'package:mybudget/ui/transfers/widgets/transfer_bottom_sheet.dart';
import 'package:mybudget/utils/history_utils.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  final AccountModel account;

  const AccountDetailsScreen({required this.account, super.key});

  @override
  ConsumerState<AccountDetailsScreen> createState() =>
      _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  late AccountModel account;

  @override
  void initState() {
    super.initState();
    account = widget.account;
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final expenses = ref.watch(expenseProvider).value ?? [];
    final revenues = ref.watch(revenueProvider).value ?? [];
    final loans = ref.watch(loanProvider).value ?? [];

    final totalRevenues = revenues
        .where((r) => r.accountId == account.id)
        .where((r) => isActiveForMonth(r.startDate, r.endDate, selectedMonth))
        .fold(0.0, (sum, r) {
      switch (r.frequencyEnum) {
        case Frequency.monthly:
          return sum + r.amount;
        case Frequency.annual:
          return r.startDate.month == selectedMonth.month
              ? sum + r.amount
              : sum;
        case Frequency.oneTime:
          return r.startDate.year == selectedMonth.year &&
                  r.startDate.month == selectedMonth.month
              ? sum + r.amount
              : sum;
      }
    });

    final totalExpenses = expenses
        .where((e) => e.accountId == account.id)
        .where((e) => isActiveForMonth(e.startDate, e.endDate, selectedMonth))
        .fold(0.0, (sum, e) {
      switch (e.frequencyEnum) {
        case Frequency.monthly:
          return sum + e.amount;
        case Frequency.annual:
          return e.startDate.month == selectedMonth.month
              ? sum + e.amount
              : sum;
        case Frequency.oneTime:
          return e.startDate.year == selectedMonth.year &&
                  e.startDate.month == selectedMonth.month
              ? sum + e.amount
              : sum;
      }
    });

    final totalLoanPayments = loans
        .where((l) => l.accountId == account.id && !l.isCompleted)
        .fold(0.0, (sum, loan) => sum + loan.currentMonthlyPayment);

    final transferNotifier = ref.watch(transferProvider.notifier);
    final totalTransfers =
        transferNotifier.getMonthlyTransferBalance(account.id);
    final transfers = transferNotifier.getActiveTransfersForAccount(account.id);
    final accounts = ref.watch(accountProvider).value ?? [];

    final balance =
        totalRevenues - totalExpenses - totalLoanPayments + totalTransfers;

    final topInset = MediaQuery.of(context).padding.top;

    return FrostedScaffold(
      appBar: AppTopBar(title: account.name),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + kToolbarHeight + 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccountHeroCard(
              account: account,
              balance: balance,
            ),
            const SizedBox(height: 14),
            AccountBalanceBreakdown(
              totalRevenues: totalRevenues,
              totalExpenses: totalExpenses,
              totalLoanPayments: totalLoanPayments,
              totalTransfers: totalTransfers,
              balance: balance,
            ),
            _TransfersSection(
              transfers: transfers,
              currentAccountId: account.id,
              accounts: accounts,
              onEditTransfer: (t) => _showEditTransferBottomSheet(context, t),
            ),
            const SizedBox(height: 16),
            FrostedFilledButton.icon(
              onPressed: () => _showAddTransferBottomSheet(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un virement'),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FrostedTonalButton.icon(
                    onPressed: () => _showEditAccountBottomSheet(context),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FrostedOutlinedButton.icon(
                    onPressed: () => _showDeleteConfirmation(context),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Supprimer'),
                    foregroundColor: Theme.of(context).colorScheme.error,
                    borderColor: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de la modification: $e',
            );
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
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de l\'ajout du virement: $e',
            );
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
          await ref
              .read(transferProvider.notifier)
              .updateTransfer(updatedTransfer);
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de la modification du virement: $e',
            );
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final linkedExpenses =
        ref.read(expenseProvider.notifier).getExpensesForAccount(account.id);
    final linkedRevenues =
        ref.read(revenueProvider.notifier).getRevenuesForAccount(account.id);
    final linkedLoans =
        ref.read(loanProvider.notifier).getActiveLoansForAccount(account.id);
    final linkedTransfers =
        ref.read(transferProvider.notifier).getTransfersForAccount(account.id);

    final totalLinked = linkedExpenses.length +
        linkedRevenues.length +
        linkedLoans.length +
        linkedTransfers.length;

    if (totalLinked > 0) {
      final parts = <String>[];
      if (linkedExpenses.isNotEmpty) {
        parts.add(
            '${linkedExpenses.length} dépense${linkedExpenses.length > 1 ? 's' : ''}');
      }
      if (linkedRevenues.isNotEmpty) {
        parts.add(
            '${linkedRevenues.length} revenu${linkedRevenues.length > 1 ? 's' : ''}');
      }
      if (linkedLoans.isNotEmpty) {
        parts.add(
            '${linkedLoans.length} emprunt${linkedLoans.length > 1 ? 's' : ''}');
      }
      if (linkedTransfers.isNotEmpty) {
        parts.add(
            '${linkedTransfers.length} virement${linkedTransfers.length > 1 ? 's' : ''}');
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
              await ref
                  .read(accountProvider.notifier)
                  .deleteAccount(account.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.of(context).pop();
                FrostedSnackbar.show(
                  context,
                  message: 'Erreur lors de la suppression: $e',
                );
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

class _TransfersSection extends StatelessWidget {
  final List<Transfer> transfers;
  final int currentAccountId;
  final List<AccountModel> accounts;
  final ValueChanged<Transfer> onEditTransfer;

  const _TransfersSection({
    required this.transfers,
    required this.currentAccountId,
    required this.accounts,
    required this.onEditTransfer,
  });

  String _otherName(Transfer transfer) {
    final otherId = transfer.isOutgoingFrom(currentAccountId)
        ? transfer.toAccountId
        : transfer.fromAccountId;
    final other = accounts.where((a) => a.id == otherId).firstOrNull;
    return other?.name ?? 'Compte inconnu';
  }

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Virements actifs', trailing: '0'),
          SolidCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: Text(
                'Aucun virement',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Virements actifs',
          trailing: '${transfers.length}',
        ),
        SolidCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < transfers.length; i++)
                TransferRow(
                  transfer: transfers[i],
                  currentAccountId: currentAccountId,
                  otherAccountName: _otherName(transfers[i]),
                  showDivider: i < transfers.length - 1,
                  onTap: () => onEditTransfer(transfers[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

