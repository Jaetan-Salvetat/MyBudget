import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/entities/monthly_flow.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/locales.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/animated_amount.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';

class MonthlyFlowSection extends StatelessWidget {
  const MonthlyFlowSection({
    super.key,
    required this.flows,
    required this.averageNet,
    required this.netDelta,
    required this.hasComparison,
    required this.onMonthTap,
  });
  final List<MonthlyFlow> flows;
  final double averageNet;
  final double netDelta;
  final bool hasComparison;
  final ValueChanged<DateTime> onMonthTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'Flux mensuels', trailing: _windowLabel()),
        SolidCard(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Headline(
                averageNet: averageNet,
                netDelta: netDelta,
                hasComparison: hasComparison,
              ),
              const SizedBox(height: 18),
              _Chart(flows: flows, onMonthTap: onMonthTap),
              const SizedBox(height: 12),
              const _Legend(),
            ],
          ),
        ),
      ],
    );
  }

  String _windowLabel() {
    if (flows.isEmpty) return '';
    final start = DateFormatter.shortMonth.format(flows.first.month);
    final end = DateFormatter.shortMonthYear.format(flows.last.month);
    return '$start — $end';
  }
}

class _Headline extends StatelessWidget {
  const _Headline({
    required this.averageNet,
    required this.netDelta,
    required this.hasComparison,
  });
  final double averageNet;
  final double netDelta;
  final bool hasComparison;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final color = averageNet >= 0 ? finance.income : finance.expense;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedAmount(
                amount: averageNet,
                builder: (context, value) => RichText(
                  text: TextSpan(
                    style: AppTextStyles.displaySerifItalic(
                      fontSize: 34,
                      color: color,
                    ),
                    children: [
                      TextSpan(text: _rounded(value)),
                      TextSpan(
                        text: ' ${FinancialLocale.currencySymbol}/mois',
                        style: AppTextStyles.displaySerifItalic(
                          fontSize: 19,
                          color: color.withValues(alpha: 0.66),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                averageNet >= 0
                    ? 'mis de côté en moyenne'
                    : 'de découvert en moyenne',
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (hasComparison) _DeltaPill(delta: netDelta),
      ],
    );
  }

  String _rounded(double value) {
    return '${MoneyFormatter.signOf(value)}'
        '${MoneyFormatter.formatPlainRounded(value.abs())}';
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final improving = delta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: improving ? finance.incomeSoft : finance.expenseSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '${MoneyFormatter.signOf(delta)}'
        '${MoneyFormatter.formatRounded(delta.abs())} /mois',
        style: AppTextStyles.mono(
          fontSize: 10.5,
          lineHeight: 14,
          fontWeight: FontWeight.w600,
          color: improving ? finance.incomeOnSoft : finance.expenseOnSoft,
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.flows, required this.onMonthTap});
  final List<MonthlyFlow> flows;
  final ValueChanged<DateTime> onMonthTap;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;

    return FrostedPairedColumnChart(
      columns: [
        for (final flow in flows)
          FrostedPairedColumnData(
            primary: flow.incomes,
            secondary: flow.expenses,
            label: _label(flow.month),
          ),
      ],
      primaryColor: finance.income,
      secondaryColor: finance.expense,
      maxAxisLabels: flows.length,
      animated: true,
      labelStyle: AppTextStyles.mono(
        fontSize: 8.5,
        lineHeight: 12,
        letterSpacingEm: 0.04,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onColumnTap: (index) => onMonthTap(flows[index].month),
    );
  }

  String _label(DateTime month) =>
      DateFormatter.shortMonth.format(month).replaceAll('.', '').toUpperCase();
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final scheme = Theme.of(context).colorScheme;

    return FrostedChartLegend(
      entries: [
        FrostedLegendEntry(color: finance.income, label: 'entré'),
        FrostedLegendEntry(color: finance.expense, label: 'sorti'),
      ],
      labelStyle: AppTextStyles.mono(
        fontSize: 9.5,
        lineHeight: 12,
        letterSpacingEm: 0.04,
        color: scheme.onSurfaceVariant,
      ),
      trailing: Text(
        'tap → le mois',
        style: AppTextStyles.mono(
          fontSize: 9.5,
          lineHeight: 12,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
