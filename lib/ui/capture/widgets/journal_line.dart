import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';

/// One transaction of the journal. Every line carries the same typographic
/// weight : what tells them apart is the avatar, the category colour and the
/// place in the day — never a bigger number.
///
/// The avatar is the app's own [TransactionAvatar], the one the expenses and
/// revenues lists already draw : one transaction, one face, wherever it is
/// read.
class JournalLine extends StatelessWidget {
  static const double radius = 18;
  static const Duration coolDown = Duration(milliseconds: 600);

  static const double _freshOpacity = 0.13;

  final JournalEntry entry;
  final CategoryDisplay? category;

  /// The slice the line sits in already names the day : the meta then shows
  /// the hour. Further back it is the day that has to be said.
  final bool keepsTheHour;

  /// The line just landed : it holds its tint and its way back for as long as
  /// the undo window lasts, then cools into the list.
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

    return AnimatedContainer(
      duration: coolDown,
      curve: context.frostedTokens.motion.fluid.curve,
      decoration: BoxDecoration(
        color: isFresh
            ? tone.withValues(alpha: _freshOpacity)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Material(
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
      ),
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
    if (!keepsTheHour) return DateFormat('EEE d', 'fr_FR').format(entry.at);
    return entry.hasTime ? DateFormat.Hm('fr_FR').format(entry.at) : null;
  }

  String _amountLabel() {
    final formatted = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    ).format(entry.amount);
    return entry.isIncome ? '+ $formatted' : '− $formatted';
  }
}

class _UndoLink extends StatelessWidget {
  final VoidCallback onTap;

  const _UndoLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FrostedRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.sp2,
          vertical: FrostedSpacing.sp1,
        ),
        child: Text(
          'Annuler',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
