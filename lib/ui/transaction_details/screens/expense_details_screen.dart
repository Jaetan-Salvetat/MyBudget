import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/entities/transaction_rule_version.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/services/transaction_rule_summary_service.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/expenses/screens/expense_form_screen.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/transaction_details/widgets/missing_transaction_view.dart';
import 'package:mybudget/ui/transaction_details/widgets/transaction_details_view.dart';

const String _screenTitle = 'Détail de la dépense';
const String _missingMessage = 'Cette dépense n\'existe plus';
const String _deleteMessage = 'Voulez-vous vraiment supprimer cette dépense ?';

class ExpenseDetailsScreen extends ConsumerStatefulWidget {
  final int expenseId;
  final bool isCurrentMonth;

  const ExpenseDetailsScreen({
    required this.expenseId,
    required this.isCurrentMonth,
    super.key,
  });

  static Future<void> push({
    required BuildContext context,
    required int expenseId,
    required bool isCurrentMonth,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseDetailsScreen(
          expenseId: expenseId,
          isCurrentMonth: isCurrentMonth,
        ),
      ),
    );
  }

  @override
  ConsumerState<ExpenseDetailsScreen> createState() =>
      _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends ConsumerState<ExpenseDetailsScreen> {
  late int _expenseId;

  @override
  void initState() {
    super.initState();
    _expenseId = widget.expenseId;
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(expenseHistoryProvider);
    final expense = history.where((e) => e.id == _expenseId).firstOrNull;
    if (expense == null) {
      return const MissingTransactionView(
        title: _screenTitle,
        message: _missingMessage,
      );
    }

    final chain = _chainOf(history, expense);
    final versions = [
      for (final entry in chain)
        TransactionRuleVersion(
          amount: entry.amount,
          startDate: entry.startDate,
          endDate: entry.endDate,
          frequency: entry.frequencyEnum,
        ),
    ];

    final accounts = ref.watch(accountProvider).value ?? [];
    final account = accounts
        .where((a) => a.id == expense.accountId)
        .firstOrNull;
    final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];
    final beneficiary = expense.beneficiaryId == null
        ? null
        : beneficiaries
              .where((b) => b.id == expense.beneficiaryId)
              .firstOrNull;
    final slug = expense.categorySlug;
    final category = slug == null
        ? null
        : ref.watch(categoryDisplayResolverProvider).value?.resolve(slug);

    return TransactionDetailsView(
      screenTitle: _screenTitle,
      name: expense.name,
      category: category,
      beneficiary: beneficiary,
      accountLabel: _accountLabel(account),
      amount: expense.amount,
      frequency: expense.frequencyEnum,
      startDate: expense.startDate,
      endDate: expense.endDate,
      summary: TransactionRuleSummaryService.summarize(
        versions,
        asOf: DateTime.now(),
      ),
      versions: versions,
      isIncome: false,
      fallbackIcon: Symbols.receipt_long_rounded,
      fallbackColor: context.financeColors.expense,
      isEditable: widget.isCurrentMonth && expense.endDate == null,
      receiptPath: expense.receiptPath,
      deleteConfirmationMessage: _deleteMessage,
      onEdit: () => _openEditScreen(expense),
      onDelete: _deleteExpense,
    );
  }

  List<ExpenseModel> _chainOf(
    List<ExpenseModel> history,
    ExpenseModel expense,
  ) {
    final rootId = expense.parentId ?? expense.id;
    return history
        .where((entry) => entry.id == rootId || entry.parentId == rootId)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  String _accountLabel(AccountModel? account) {
    if (account == null) return 'Compte inconnu';
    return account.bank.isEmpty
        ? account.name
        : '${account.name} · ${account.bank}';
  }

  Future<void> _openEditScreen(ExpenseModel expense) async {
    final updated = await ExpenseFormScreen.push(
      context: context,
      accounts: ref.read(accountProvider).value ?? [],
      expense: expense,
    );
    if (updated == null) return;

    try {
      await ref.read(expenseProvider.notifier).updateExpense(updated);
      _followChain(expense);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de la modification: $e',
        );
      }
    }
  }

  void _followChain(ExpenseModel expense) {
    if (!mounted) return;
    final rootId = expense.parentId ?? expense.id;
    final open = ref
        .read(expenseHistoryProvider)
        .where(
          (entry) =>
              (entry.id == rootId || entry.parentId == rootId) &&
              entry.endDate == null,
        )
        .firstOrNull;
    if (open == null || open.id == _expenseId) return;
    setState(() => _expenseId = open.id);
  }

  Future<void> _deleteExpense(RecurringDeletion scope) async {
    try {
      await ref
          .read(expenseProvider.notifier)
          .deleteExpense(_expenseId, scope: scope);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de la suppression: $e',
        );
      }
    }
  }
}
