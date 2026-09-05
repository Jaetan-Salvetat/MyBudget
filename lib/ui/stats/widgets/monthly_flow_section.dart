import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/entities/monthly_flow.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/animated_amount.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';

class MonthlyFlowSection extends StatelessWidget {
  static const double chartHeight = 128;
  static const double minimumColumnFactor = 0.02;

  final List<MonthlyFlow> flows;
  final double averageNet;
  final double netDelta;
  final bool hasComparison;
  final ValueChanged<DateTime> onMonthTap;

  const MonthlyFlowSection({
    super.key,
    required this.flows,
    required this.averageNet,
    required this.netDelta,
    required this.hasComparison,
    required this.onMonthTap,
  });

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
    final start = DateFormat('MMM', 'fr_FR').format(flows.first.month);
    final end = DateFormat('MMM yyyy', 'fr_FR').format(flows.last.month);
    return '$start — $end';
  }
}

class _Headline extends StatelessWidget {
  final double averageNet;
  final double netDelta;
  final bool hasComparison;

  const _Headline({
    required this.averageNet,
    required this.netDelta,
    required this.hasComparison,
  });

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
                        text: ' €/mois',
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
    final formatter = NumberFormat.decimalPattern('fr_FR')
      ..maximumFractionDigits = 0;
    final sign = value < 0 ? '−' : '+';
    return '$sign${formatter.format(value.abs())}';
  }
}

class _DeltaPill extends StatelessWidget {
  final double delta;

  const _DeltaPill({required this.delta});

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final improving = delta >= 0;
    final formatter = NumberFormat.decimalPattern('fr_FR')
      ..maximumFractionDigits = 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: improving ? finance.incomeSoft : finance.expenseSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '${improving ? '+' : '−'}${formatter.format(delta.abs())} € /mois',
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
  final List<MonthlyFlow> flows;
  final ValueChanged<DateTime> onMonthTap;

  const _Chart({required this.flows, required this.onMonthTap});

  @override
  Widget build(BuildContext context) {
    final scale = _scale();

    return Column(
      children: [
        SizedBox(
          height: MonthlyFlowSection.chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final flow in flows)
                Expanded(
                  child: _Column(
                    flow: flow,
                    scale: scale,
                    onTap: () => onMonthTap(flow.month),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var index = 0; index < flows.length; index++)
              Expanded(
                child: Text(
                  _tick(index),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.mono(
                    fontSize: 8.5,
                    lineHeight: 12,
                    letterSpacingEm: 0.04,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  double _scale() {
    double scale = 0;
    for (final flow in flows) {
      scale = [
        scale,
        flow.incomes,
        flow.expenses,
      ].reduce((a, b) => a > b ? a : b);
    }
    return scale;
  }

  String _tick(int index) {
    final everyOther = (flows.length - 1 - index).isEven;
    if (flows.length > 6 && !everyOther) return '';
    final label = DateFormat('MMM', 'fr_FR').format(flows[index].month);
    return label.replaceAll('.', '').toUpperCase();
  }
}

class _Column extends StatelessWidget {
  final MonthlyFlow flow;
  final double scale;
  final VoidCallback onTap;

  const _Column({required this.flow, required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final peak = flow.incomes > flow.expenses ? flow.incomes : flow.expenses;
    final factor = scale <= 0 ? 0.0 : peak / scale;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: factor.clamp(
              MonthlyFlowSection.minimumColumnFactor,
              1.0,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
                bottom: Radius.circular(2),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: finance.incomeSoft),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: peak <= 0 ? 0.0 : flow.expenses / peak,
                      child: ColoredBox(color: finance.expense),
                    ),
                  ),
                  if (peak > 0)
                    Align(
                      alignment: Alignment(0, 1 - 2 * (flow.incomes / peak)),
                      child: SizedBox(
                        height: 2,
                        width: double.infinity,
                        child: ColoredBox(color: finance.income),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.only(top: 11),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _LegendKey(color: finance.income, label: 'entré'),
          const SizedBox(width: 14),
          _LegendKey(color: finance.expense, label: 'sorti'),
          const Spacer(),
          Text(
            'tap → le mois',
            style: AppTextStyles.mono(
              fontSize: 9.5,
              lineHeight: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendKey extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendKey({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.mono(
            fontSize: 9.5,
            lineHeight: 12,
            letterSpacingEm: 0.04,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
