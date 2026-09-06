import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/stats/models/category_trend.dart';

class CategoryMoversSection extends StatelessWidget {
  const CategoryMoversSection({
    super.key,
    required this.movers,
    required this.comparedMonths,
    required this.hasComparison,
    required this.onCategoryTap,
  });
  static const int maxVisible = 5;

  final List<CategoryTrend> movers;
  final int comparedMonths;
  final bool hasComparison;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Ce qui a bougé',
          trailing: hasComparison ? 'vs $comparedMonths mois précédents' : null,
        ),
        movers.isEmpty
            ? _EmptyCard(message: _emptyMessage)
            : _MoversCard(
                movers: movers.take(maxVisible).toList(),
                onCategoryTap: onCategoryTap,
              ),
      ],
    );
  }

  String get _emptyMessage => hasComparison
      ? 'Aucun poste n\u2019a bougé sur la période'
      : 'Pas encore assez d\u2019historique pour comparer les $comparedMonths mois précédents';
}

class _MoversCard extends StatelessWidget {
  const _MoversCard({required this.movers, required this.onCategoryTap});
  final List<CategoryTrend> movers;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final widest = movers
        .map((trend) => trend.delta.abs())
        .reduce((a, b) => a > b ? a : b);

    return SolidCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final trend in movers)
            _MoverRow(
              trend: trend,
              widest: widest,
              isFirst: trend == movers.first,
              onTap: () => onCategoryTap(trend.groupKey),
            ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return SolidCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({
    required this.trend,
    required this.widest,
    required this.isFirst,
    required this.onTap,
  });
  static const double nameWidth = 92;
  static const double amountWidth = 64;

  final CategoryTrend trend;
  final double widest;
  final bool isFirst;
  final VoidCallback onTap;

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
    return '${MoneyFormatter.signOf(delta)}'
        '${MoneyFormatter.formatRounded(delta.abs())}';
  }
}
