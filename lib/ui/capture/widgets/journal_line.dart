import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';

/// One transaction of the day. Every line carries the same typographic
/// weight : what tells them apart is the initial, the category tint and the
/// place in the day — never a bigger number.
class JournalLine extends StatelessWidget {
  static const double avatarSize = 36;
  static const double radius = 18;
  static const Duration coolDown = Duration(milliseconds: 600);

  static const double _tintOpacity = 0.17;
  static const double _borderOpacity = 0.26;
  static const double _freshOpacity = 0.13;
  static const double _inkBlend = 0.78;

  final JournalEntry entry;
  final CategoryDisplay? category;

  /// The line just landed : it holds its tint and its way back for as long as
  /// the undo window lasts, then cools into the list.
  final bool isFresh;

  final VoidCallback? onUndo;
  final VoidCallback? onTap;

  const JournalLine({
    required this.entry,
    required this.category,
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
                _Avatar(entry: entry, category: category, tone: tone),
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
    if (!entry.hasTime) return label ?? '';

    final time = DateFormat.Hm('fr_FR').format(entry.at);
    return label == null ? time : '$time · $label';
  }

  String _amountLabel() {
    final formatted = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    ).format(entry.amount);
    return entry.isIncome ? '+ $formatted' : '− $formatted';
  }
}

/// The initial of the merchant in a disc tinted by its category : four
/// identical basket icons told nothing apart.
class _Avatar extends StatelessWidget {
  final JournalEntry entry;
  final CategoryDisplay? category;
  final Color tone;

  const _Avatar({
    required this.entry,
    required this.category,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    final initials = _initials(entry.name);

    return Container(
      width: JournalLine.avatarSize,
      height: JournalLine.avatarSize,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: JournalLine._tintOpacity),
        shape: BoxShape.circle,
        border: Border.all(
          color: tone.withValues(alpha: JournalLine._borderOpacity),
        ),
      ),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? Icon(
              _icon(category),
              size: 19,
              color: ink,
              fill: 1,
            )
          : Text(
              initials,
              style: TextStyle(
                fontSize: 15,
                height: 1,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.15,
                color: ink,
              ),
            ),
    );
  }

  static IconData _icon(CategoryDisplay? category) => category == null
      ? Symbols.category_rounded
      : CategoryDefaults.resolveIcon(category.icon);

  /// The palette is tuned for a dark ground ; on a light one the same hue has
  /// to be taken down before it can carry a letter.
  Color _ink(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return tone;
    return Color.alphaBlend(
      tone.withValues(alpha: JournalLine._inkBlend),
      Colors.black,
    );
  }

  static String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && _isLetter(word[0]))
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  static bool _isLetter(String character) =>
      character.toLowerCase() != character.toUpperCase();
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
