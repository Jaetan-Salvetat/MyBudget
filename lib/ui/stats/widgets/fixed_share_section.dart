import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';

class FixedShareSection extends StatelessWidget {
  final double share;
  final double shareDelta;
  final double recurringExpenses;
  final double variableExpenses;
  final bool hasComparison;

  const FixedShareSection({
    super.key,
    required this.share,
    required this.shareDelta,
    required this.recurringExpenses,
    required this.variableExpenses,
    required this.hasComparison,
  });

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Part incompressible',
          trailing: hasComparison ? _deltaLabel() : null,
        ),
        SolidCard(
          padding: const EdgeInsets.fromLTRB(15, 16, 15, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(share * 100).round()} %',
                    style: AppTextStyles.displaySerifItalic(
                      fontSize: 38,
                      height: 1,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'de tes sorties tombent quoi qu\'il arrive',
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _SplitBar(
                recurring: recurringExpenses,
                variable: variableExpenses,
                recurringColor: finance.expense,
                variableColor: finance.expenseSoft,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Récurrent ${_money(recurringExpenses)}',
                    style: AppTextStyles.mono(
                      fontSize: 9.5,
                      lineHeight: 13,
                      letterSpacingEm: 0.03,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Ponctuel ${_money(variableExpenses)}',
                    style: AppTextStyles.mono(
                      fontSize: 9.5,
                      lineHeight: 13,
                      letterSpacingEm: 0.03,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _deltaLabel() {
    final points = (shareDelta * 100).round();
    if (points == 0) return 'stable';
    return '${points > 0 ? '+' : '−'}${points.abs()} pts';
  }

  String _money(double amount) => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  ).format(amount);
}

class _SplitBar extends StatelessWidget {
  static const double barHeight = 9;

  final double recurring;
  final double variable;
  final Color recurringColor;
  final Color variableColor;

  const _SplitBar({
    required this.recurring,
    required this.variable,
    required this.recurringColor,
    required this.variableColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = recurring + variable;
    if (total <= 0) {
      return Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: variableColor,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    return SizedBox(
      height: barHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: (recurring * 1000).round().clamp(0, 1000000),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: recurringColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: (variable * 1000).round().clamp(0, 1000000),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: variableColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
