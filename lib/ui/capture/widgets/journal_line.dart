import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';

class JournalLine extends StatelessWidget {
  static const double radius = 18;

  static const double _railInset = 6;

  final JournalEntry entry;
  final CategoryDisplay? category;

  final bool keepsTheHour;

  final bool isFresh;

  final VoidCallback? onUndo;
  final VoidCallback? onTap;

  const JournalLine({
    required this.entry,
    required this.category,
    required this.keepsTheHour,
    required this.isFresh,
    this.onUndo,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _tone(context);

    final line = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.all(FrostedSpacing.sp2),
          child: Row(
            children: [
              TransactionAvatar(
                color: tone,
                icon: category == null
                    ? Symbols.category_rounded
                    : CategoryDefaults.resolveIcon(category!.icon),
              ),
              const SizedBox(width: FrostedSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.012 * 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _meta(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.mono(
                        fontSize: 10,
                        lineHeight: 14,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.68,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FrostedSpacing.sp2),
              Text(
                _amountLabel(),
                style: AppTextStyles.displaySerifItalic(
                  fontSize: 17,
                  height: 1.15,
                  color: entry.isIncome
                      ? context.financeColors.income
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (onUndo != null) _UndoLink(onTap: onUndo!),
            ],
          ),
        ),
      ),
    );

    if (!isFresh) return line;

    return Stack(
      children: [
        line,
        PositionedDirectional(
          start: 0,
          top: _railInset,
          bottom: _railInset,
          width: _UndoRail.width,
          child: _UndoRail(color: tone),
        ),
      ],
    );
  }

  Color _tone(BuildContext context) {
    final display = category;
    if (display == null) return Theme.of(context).colorScheme.primary;
    return Color(display.color);
  }

  String _meta() {
    final label = category?.label;
    final when = _when();
    if (when == null) return label ?? '';

    return label == null ? when : '$when · $label';
  }

  String? _when() {
    if (!keepsTheHour) return DateFormatter.weekdayDay.format(entry.at);
    return entry.hasTime ? DateFormatter.time.format(entry.at) : null;
  }

  String _amountLabel() {
    final formatted = MoneyFormatter.format(entry.amount);
    return entry.isIncome ? '+ $formatted' : '− $formatted';
  }
}

class _UndoRail extends StatelessWidget {
  static const double width = 2;

  final Color color;

  const _UndoRail({required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: QuickAddRecentSubmissions.retention,
      curve: Curves.linear,
      builder: (context, remaining, _) => FractionallySizedBox(
        alignment: Alignment.topCenter,
        heightFactor: remaining,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(width),
          ),
        ),
      ),
    );
  }
}

class _UndoLink extends StatelessWidget {
  final VoidCallback onTap;

  const _UndoLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FrostedRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.sp2,
          vertical: FrostedSpacing.sp1,
        ),
        child: Text(
          'annuler',
          style: AppTextStyles.mono(
            fontSize: 10,
            lineHeight: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
