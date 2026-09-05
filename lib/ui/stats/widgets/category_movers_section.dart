import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/stats/models/category_trend.dart';

class CategoryMoversSection extends StatelessWidget {
  static const int maxVisible = 5;

  final List<CategoryTrend> movers;
  final int comparedMonths;
  final ValueChanged<String> onCategoryTap;

  const CategoryMoversSection({
    super.key,
    required this.movers,
    required this.comparedMonths,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (movers.isEmpty) return const SizedBox.shrink();

    final visible = movers.take(maxVisible).toList();
    final widest = visible
        .map((trend) => trend.delta.abs())
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Ce qui a bougé',
          trailing: 'vs $comparedMonths mois précédents',
        ),
        SolidCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final trend in visible)
                _MoverRow(
                  trend: trend,
                  widest: widest,
                  isFirst: trend == visible.first,
                  onTap: () => onCategoryTap(trend.groupKey),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoverRow extends StatelessWidget {
  static const double nameWidth = 92;
  static const double amountWidth = 64;

  final CategoryTrend trend;
  final double widest;
  final bool isFirst;
  final VoidCallback onTap;

  const _MoverRow({
    required this.trend,
    required this.widest,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final scheme = Theme.of(context).colorScheme;
    final rising = trend.delta >= 0;
    final color = rising ? finance.expense : finance.income;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: isFirst
            ? null
            : BoxDecoration(
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant, width: 0.5),
                ),
              ),
        child: Row(
          children: [
            SizedBox(
              width: nameWidth,
              child: Row(
                children: [
                  FrostedChartDot(color: trend.color),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      trend.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 16 / 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: FrostedDivergingBar(
                factor: widest <= 0 ? 0 : trend.delta.abs() / widest,
                side: rising
                    ? FrostedDivergingSide.trailing
                    : FrostedDivergingSide.leading,
                color: color,
                axisColor: scheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: amountWidth,
              child: Text(
                _signed(trend.delta),
                textAlign: TextAlign.right,
                style: AppTextStyles.mono(
                  fontSize: 11.5,
                  lineHeight: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _signed(double delta) {
    final formatter = NumberFormat.decimalPattern('fr_FR')
      ..maximumFractionDigits = 0;
    return '${delta >= 0 ? '+' : '−'}${formatter.format(delta.abs())} €';
  }
}
