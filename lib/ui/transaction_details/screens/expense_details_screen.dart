import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/entities/transaction_rule_version.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/services/transaction_rule_summary_service.dart';
import 'package:mybudget/core/services/transaction_timeline_service.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/widgets/recurring_edit_scope_dialog.dart';
import 'package:mybudget/ui/expenses/expense_queries.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/expenses/screens/expense_form_screen.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/transaction_details/transaction_event_presenter.dart';
import 'package:mybudget/ui/transaction_details/widgets/missing_transaction_view.dart';
import 'package:mybudget/ui/transaction_details/widgets/transaction_details_view.dart';

const String _screenTitle = 'Détail de la dépense';
const String _missingMessage = 'Cette dépense n\'existe plus';
const String _unknownAccount = 'Compte inconnu';
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

    final accounts = ref.watch(accountProvider).value ?? [];
    final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];
    final resolver = ref.watch(categoryDisplayResolverProvider).value;

    final account = accounts
        .where((a) => a.id == expense.accountId)
        .firstOrNull;
    final beneficiary = _beneficiaryOf(expense.beneficiaryId, beneficiaries);
    final slug = expense.categorySlug;
    final category = slug == null ? null : resolver?.resolve(slug);

    final chain = _chainOf(history, expense);
    final versions = _versionsOf(chain, accounts, beneficiaries);
    final rootId = expense.parentId ?? expense.id;
    final presenter = TransactionEventPresenter(
      resolver: resolver,
      accounts: accounts,
      beneficiaries: beneficiaries,
      formatter: _formatter,
    );

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
      timeline: TransactionTimelineService.build(
        versions: versions,
        recorded: [
          for (final event in ref.watch(expenseEventsProvider(rootId)))
            presenter.describe(event),
        ],
        formatAmount: _formatter.format,
      ),
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

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
  );

  List<TransactionRuleVersion> _versionsOf(
    List<ExpenseModel> chain,
    List<AccountModel> accounts,
    List<Beneficiary> beneficiaries,
  ) {
    return [
      for (final entry in chain)
        TransactionRuleVersion(
          name: entry.name,
          amount: entry.amount,
          startDate: entry.startDate,
          endDate: entry.endDate,
          frequency: entry.frequencyEnum,
          accountLabel:
              accounts.where((a) => a.id == entry.accountId).firstOrNull?.name ??
              _unknownAccount,
          beneficiaryLabel: _beneficiaryOf(
            entry.beneficiaryId,
            beneficiaries,
          )?.name,
        ),
    ];
  }

  Beneficiary? _beneficiaryOf(int? id, List<Beneficiary> beneficiaries) {
    if (id == null) return null;
    return beneficiaries.where((b) => b.id == id).firstOrNull;
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
    if (account == null) return _unknownAccount;
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
    if (updated == null || !mounted) return;

    await RecurringEditScopeDialog.submit(
      context: context,
      before: expense,
      after: updated,
      onConfirmed: (effectiveMonth) => _saveExpense(
        expense,
        updated,
        effectiveMonth: effectiveMonth,
      ),
    );
  }

  Future<void> _saveExpense(
    ExpenseModel expense,
    ExpenseModel updated, {
    required EffectiveMonth? effectiveMonth,
  }) async {
    try {
      await ref
          .read(expenseProvider.notifier)
          .updateExpense(updated, effectiveMonth: effectiveMonth);
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
