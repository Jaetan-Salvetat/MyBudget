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
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/revenues/screens/revenue_form_screen.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/transaction_details/transaction_event_presenter.dart';
import 'package:mybudget/ui/transaction_details/widgets/missing_transaction_view.dart';
import 'package:mybudget/ui/transaction_details/widgets/transaction_details_view.dart';

const String _screenTitle = 'Détail du revenu';
const String _missingMessage = 'Ce revenu n\'existe plus';
const String _unknownAccount = 'Compte inconnu';
const String _deleteMessage = 'Voulez-vous vraiment supprimer ce revenu ?';

class RevenueDetailsScreen extends ConsumerStatefulWidget {
  final int revenueId;
  final bool isCurrentMonth;

  const RevenueDetailsScreen({
    required this.revenueId,
    required this.isCurrentMonth,
    super.key,
  });

  static Future<void> push({
    required BuildContext context,
    required int revenueId,
    required bool isCurrentMonth,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RevenueDetailsScreen(
          revenueId: revenueId,
          isCurrentMonth: isCurrentMonth,
        ),
      ),
    );
  }

  @override
  ConsumerState<RevenueDetailsScreen> createState() =>
      _RevenueDetailsScreenState();
}

class _RevenueDetailsScreenState extends ConsumerState<RevenueDetailsScreen> {
  late int _revenueId;

  @override
  void initState() {
    super.initState();
    _revenueId = widget.revenueId;
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(revenueHistoryProvider);
    final revenue = history.where((e) => e.id == _revenueId).firstOrNull;
    if (revenue == null) {
      return const MissingTransactionView(
        title: _screenTitle,
        message: _missingMessage,
      );
    }

    final accounts = ref.watch(accountProvider).value ?? [];
    final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];
    final resolver = ref.watch(categoryDisplayResolverProvider).value;

    final account = accounts
        .where((a) => a.id == revenue.accountId)
        .firstOrNull;
    final beneficiary = _beneficiaryOf(revenue.beneficiaryId, beneficiaries);
    final slug = revenue.categorySlug;
    final category = slug == null ? null : resolver?.resolve(slug);

    final chain = _chainOf(history, revenue);
    final versions = _versionsOf(chain, accounts, beneficiaries);
    final rootId = revenue.parentId ?? revenue.id;
    final presenter = TransactionEventPresenter(
      resolver: resolver,
      accounts: accounts,
      beneficiaries: beneficiaries,
      formatter: _formatter,
    );

    return TransactionDetailsView(
      screenTitle: _screenTitle,
      name: revenue.name,
      category: category,
      beneficiary: beneficiary,
      accountLabel: _accountLabel(account),
      amount: revenue.amount,
      frequency: revenue.frequencyEnum,
      startDate: revenue.startDate,
      endDate: revenue.endDate,
      summary: TransactionRuleSummaryService.summarize(
        versions,
        asOf: DateTime.now(),
      ),
      timeline: TransactionTimelineService.build(
        versions: versions,
        recorded: [
          for (final event in ref.watch(revenueEventsProvider(rootId)))
            presenter.describe(event),
        ],
        formatAmount: _formatter.format,
      ),
      isIncome: true,
      fallbackIcon: Symbols.savings_rounded,
      fallbackColor: context.financeColors.income,
      isEditable: widget.isCurrentMonth && revenue.endDate == null,
      deleteConfirmationMessage: _deleteMessage,
      onEdit: () => _openEditScreen(revenue),
      onDelete: _deleteRevenue,
    );
  }

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
  );

  List<TransactionRuleVersion> _versionsOf(
    List<RevenueModel> chain,
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

  List<RevenueModel> _chainOf(
    List<RevenueModel> history,
    RevenueModel revenue,
  ) {
    final rootId = revenue.parentId ?? revenue.id;
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

  Future<void> _openEditScreen(RevenueModel revenue) async {
    final updated = await RevenueFormScreen.push(
      context: context,
      accounts: ref.read(accountProvider).value ?? [],
      revenue: revenue,
    );
    if (updated == null) return;

    try {
      await ref.read(revenueProvider.notifier).updateRevenue(updated);
      _followChain(revenue);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de la modification: $e',
        );
      }
    }
  }

  void _followChain(RevenueModel revenue) {
    if (!mounted) return;
    final rootId = revenue.parentId ?? revenue.id;
    final open = ref
        .read(revenueHistoryProvider)
        .where(
          (entry) =>
              (entry.id == rootId || entry.parentId == rootId) &&
              entry.endDate == null,
        )
        .firstOrNull;
    if (open == null || open.id == _revenueId) return;
    setState(() => _revenueId = open.id);
  }

  Future<void> _deleteRevenue(RecurringDeletion scope) async {
    try {
      await ref
          .read(revenueProvider.notifier)
          .deleteRevenue(_revenueId, scope: scope);
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
