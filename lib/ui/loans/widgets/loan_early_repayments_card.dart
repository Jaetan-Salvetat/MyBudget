import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/loan_event_model.dart';

class LoanEarlyRepaymentsCard extends StatelessWidget {
  final Loan loan;
  final List<LoanEventModel> events;
  final void Function(LoanEventModel) onDelete;

  const LoanEarlyRepaymentsCard({
    required this.loan,
    required this.events,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8, left: 4, right: 4),
          child: Text(
            'REMBOURSEMENTS ANTICIPÉS',
            style: AppTextStyles.mono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacingEm: 0.09,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        FrostedCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Column(
            children: [
              for (var index = 0; index < sorted.length; index++)
                _buildEventRow(
                  context,
                  sorted[index],
                  currency,
                  dateFormat,
                  showDivider: true,
                ),
              _buildSavingsRow(context, currency),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventRow(
    BuildContext context,
    LoanEventModel event,
    NumberFormat currency,
    DateFormat dateFormat, {
    required bool showDivider,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isTotal = event.type == LoanEventType.earlyRepaymentTotal;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  width: 0.5,
                  color: scheme.onSurface.withValues(alpha: 0.07),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isTotal ? Symbols.task_alt_rounded : Symbols.savings_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.type.label,
                  style: const TextStyle(fontSize: 14, height: 20 / 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _subtitleOf(event, dateFormat),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!isTotal)
            Text(
              currency.format(event.amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          FrostedIconButton.standard(
            icon: Symbols.delete_rounded,
            size: FrostedIconButtonSize.small,
            onPressed: () => onDelete(event),
          ),
        ],
      ),
    );
  }

  String _subtitleOf(LoanEventModel event, DateFormat dateFormat) {
    final date = dateFormat.format(event.date);
    if (event.type == LoanEventType.earlyRepaymentTotal) return date;
    return '$date · ${event.reamortizationMode.label}';
  }

  Widget _buildSavingsRow(BuildContext context, NumberFormat currency) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Économie totale',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${currency.format(loan.costSaved)} · ${loan.monthsSaved} mois',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
