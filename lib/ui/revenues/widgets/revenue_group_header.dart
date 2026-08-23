import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/core/services/revenue_grouping_service.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_group_by_menu.dart';

/// Header of one revenue bucket: what it is, what it weighs.
///
/// The share is what the grouping is for — knowing a beneficiary brings 2 000 €
/// says less than knowing they bring 63% of the month.
class RevenueGroupHeader extends StatelessWidget {
  static const double _fullShare = 1;

  final RevenueGroup group;
  final RevenueGroupBy axis;

  const RevenueGroupHeader({
    required this.group,
    required this.axis,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );
    final color = group.color != null
        ? Color(group.color!)
        : context.financeColors.income;
    final icon = group.icon != null
        ? CategoryDefaults.resolveIcon(group.icon!)
        : revenueGroupByIcon(axis);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  group.label.toUpperCase(),
                  style: AppTextStyles.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacingEm: 0.09,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _trailingLabel(formatter),
                style: AppTextStyles.mono(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (group.share < _fullShare) ...[
            const SizedBox(height: 6),
            _ShareBar(share: group.share, color: color),
          ],
        ],
      ),
    );
  }

  String _trailingLabel(NumberFormat formatter) {
    final total = formatter.format(group.total);
    if (group.share >= _fullShare) return total;
    return '$total · ${(group.share * 100).round()} %';
  }
}

class _ShareBar extends StatelessWidget {
  static const double _height = 3;

  final double share;
  final Color color;

  const _ShareBar({required this.share, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_height),
      child: LinearProgressIndicator(
        value: share.clamp(0, 1),
        minHeight: _height,
        backgroundColor: scheme.onSurface.withValues(alpha: 0.06),
        valueColor: AlwaysStoppedAnimation<Color>(
          color.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
