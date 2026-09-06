import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/entities/transaction_change_entry.dart';
import 'package:mybudget/core/entities/transaction_rule_summary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/common/widgets/detail/detail_info_card.dart';
import 'package:mybudget/ui/common/widgets/detail/detail_kpi_card.dart';
import 'package:mybudget/ui/common/widgets/detail/detail_row.dart';
import 'package:mybudget/ui/common/widgets/transaction_actions_sheet.dart';
import 'package:mybudget/ui/transaction_details/widgets/receipt_card.dart';
import 'package:mybudget/ui/transaction_details/widgets/transaction_detail_hero.dart';
import 'package:mybudget/ui/transaction_details/widgets/transaction_timeline_card.dart';
import 'package:mybudget/utils/history_utils.dart';

const String _uncategorizedLabel = 'Non catégorisé';
const String _detailsTitle = 'Détails';
const String _endedLabel = 'Terminé';

typedef _Entry = ({String label, String value, IconData? icon});

class TransactionDetailsView extends StatelessWidget {
  final String screenTitle;
  final String name;
  final CategoryDisplay? category;
  final Beneficiary? beneficiary;
  final String accountLabel;
  final double amount;
  final Frequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final TransactionRuleSummary summary;
  final List<TransactionChangeEntry> timeline;
  final bool isIncome;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final bool isEditable;
  final String? receiptPath;
  final String deleteConfirmationMessage;
  final VoidCallback onEdit;
  final ValueChanged<RecurringDeletion> onDelete;

  const TransactionDetailsView({
    required this.screenTitle,
    required this.name,
    required this.accountLabel,
    required this.amount,
    required this.frequency,
    required this.startDate,
    required this.summary,
    required this.timeline,
    required this.isIncome,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.isEditable,
    required this.deleteConfirmationMessage,
    required this.onEdit,
    required this.onDelete,
    this.category,
    this.beneficiary,
    this.endDate,
    this.receiptPath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final path = receiptPath;

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: screenTitle,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          topInset + kToolbarHeight + 12,
          16,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TransactionDetailHero(
              name: name,
              subtitle: category?.label ?? _uncategorizedLabel,
              icon: category == null
                  ? fallbackIcon
                  : CategoryDefaults.resolveIcon(category!.icon),
              color: category == null ? fallbackColor : Color(category!.color),
              beneficiary: beneficiary,
              amount: amount,
              frequency: frequency,
              isIncome: isIncome,
              isClosed: endDate != null,
            ),
            const SizedBox(height: 14),
            _buildKpiCard(),
            DetailInfoCard(title: _detailsTitle, rows: _buildDetailRows()),
            if (timeline.length > 1) TransactionTimelineCard(entries: timeline),
            if (path != null) ReceiptCard(path: path),
            if (isEditable) ...[
              const SizedBox(height: 20),
              _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard() {
    final nextDueDate = summary.nextDueDate;
    final plural = summary.occurrences > 1 ? 's' : '';

    return DetailKpiCard(
      leftLabel: 'Cumul à ce jour',
      leftValue: MoneyFormatter.format(summary.totalToDate),
      leftHint: 'depuis ${DateFormatter.monthYear.format(summary.since)}',
      rightLabel: 'Prochaine échéance',
      rightValue: nextDueDate == null
          ? _endedLabel
          : DateFormatter.mediumDate.format(nextDueDate),
      rightHint: '${summary.occurrences} échéance$plural passée$plural',
    );
  }

  List<DetailRow> _buildDetailRows() {
    final dateFormatter = DateFormatter.numericDate;
    final annualImpact = summary.annualImpact;
    final closing = endDate;

    final entries = <_Entry>[
      (label: 'Montant', value: MoneyFormatter.format(amount), icon: null),
      (label: 'Fréquence', value: frequency.label, icon: null),
      (label: 'Échéance', value: _scheduleLabel(), icon: null),
      if (annualImpact != null)
        (
          label: 'Impact annuel',
          value: MoneyFormatter.format(annualImpact),
          icon: Symbols.calendar_month_rounded,
        ),
      (label: 'Catégorie', value: _categoryLabel(), icon: null),
      (label: 'Compte', value: accountLabel, icon: null),
      if (beneficiary != null)
        (label: 'Bénéficiaire', value: beneficiary!.name, icon: null),
      (label: 'Début', value: dateFormatter.format(startDate), icon: null),
      if (closing != null)
        (label: 'Fin', value: dateFormatter.format(closing), icon: null),
    ];

    return [
      for (var index = 0; index < entries.length; index++)
        DetailRow(
          label: entries[index].label,
          value: entries[index].value,
          icon: entries[index].icon,
          showDivider: index < entries.length - 1,
        ),
    ];
  }

  String _scheduleLabel() {
    return switch (frequency) {
      Frequency.monthly => 'Le ${startDate.day} de chaque mois',
      Frequency.annual =>
        'Le ${DateFormatter.dayMonth.format(startDate)} de chaque année',
      Frequency.oneTime => DateFormatter.longDate.format(startDate),
    };
  }

  String _categoryLabel() {
    final display = category;
    if (display == null) return _uncategorizedLabel;
    return display.isGroup
        ? display.label
        : '${display.groupLabel} · ${display.label}';
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FrostedButton.tonal(
            label: 'Modifier',
            icon: Symbols.edit_rounded,
            onPressed: onEdit,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FrostedButton.outlined(
            label: 'Supprimer',
            icon: Symbols.delete_rounded,
            destructive: true,
            onPressed: () => TransactionActionsSheet.confirmDelete(
              context: context,
              message: deleteConfirmationMessage,
              initialScope: initialDeletionScopeOf(
                startDate,
                endDate,
                frequency,
                DateTime.now(),
              ),
              onDelete: onDelete,
            ),
          ),
        ),
      ],
    );
  }
}
