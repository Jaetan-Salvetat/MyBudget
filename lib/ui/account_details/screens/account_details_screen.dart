import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/accounts/widgets/account_bottom_sheet.dart';
import 'package:mybudget/ui/account_details/widgets/account_hero_card.dart';
import 'package:mybudget/ui/account_details/widgets/account_transactions_section.dart';

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

    final expenses = ref.watch(expenseProvider).value ?? [];
    final revenues = ref.watch(revenueProvider).value ?? [];
    final loans = ref.watch(loanProvider).value ?? [];

    final totalRevenues = revenues
        .where((r) => r.accountId == account.id)
        .fold(0.0, (sum, revenue) => sum + revenue.amount);

    final totalExpenses = expenses
        .where((e) => e.accountId == account.id)
        .fold(0.0, (sum, expense) => sum + expense.amount);

    final totalLoanPayments = loans
        .where((l) => l.accountId == account.id && !l.isCompleted)
        .fold(0.0, (sum, loan) => sum + loan.currentMonthlyPayment);

    return FrostedScaffold(
      appBar: FrostedAppBar(
        title: 'Détails du compte',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditAccountBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
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
              formatter: formatter,
            ),
            const SizedBox(height: 24),
            AccountTransactionsSection(
              account: account,
              formatter: formatter,
            ),
            const SizedBox(height: 32),
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
            FrostedSnackbar.show(context, message: 'Erreur lors de la modification: \$e');
          }
        }
      },
      onCancel: () {},
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final linkedExpenses = ref.read(expenseProvider.notifier).getExpensesForAccount(account.id);
    final linkedRevenues = ref.read(revenueProvider.notifier).getRevenuesForAccount(account.id);
    final linkedLoans = ref.read(loanProvider.notifier).getActiveLoansForAccount(account.id);

    final totalLinked = linkedExpenses.length + linkedRevenues.length + linkedLoans.length;

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
