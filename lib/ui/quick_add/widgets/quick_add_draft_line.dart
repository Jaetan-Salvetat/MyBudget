import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/animated_amount.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_shimmer.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_stale.dart';

/// The category the app believes the text belongs to, ready to be drawn.
class QuickAddCategoryPreview {
  final String label;
  final IconData icon;
  final Color color;

  /// The model is not confident enough to stand behind it : the pill says so
  /// rather than passing it off as read.
  final bool isUncertain;

  const QuickAddCategoryPreview({
    required this.label,
    required this.icon,
    required this.color,
    required this.isUncertain,
  });
}

/// The transaction taking shape under the text : the amount in the app's own
/// numerals, the category landing next to it, the metadata a quiet line
/// below. Reads as the line it will become, not as a form.
class QuickAddDraftLine extends StatelessWidget {
  final double? amount;
  final bool isIncome;

  /// Null only while the first reading has yet to land : the pill then says
  /// the model is still reading.
  final QuickAddCategoryPreview? category;

  final String? recurrenceLabel;
  final String? dateLabel;

  /// The model has yet to read the text being typed. Only what it produces
  /// dims and stops answering : the amount and the date are re-read at every
  /// keystroke and are never behind.
  final bool isStale;

  final VoidCallback onPickCategory;
  final VoidCallback onPickDate;

  const QuickAddDraftLine({
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.recurrenceLabel,
    required this.dateLabel,
    required this.isStale,
    required this.onPickCategory,
    required this.onPickDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (amount == null && category == null && dateLabel == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: amount == null
                  ? const SizedBox.shrink()
                  : _DraftAmount(amount: amount!, isIncome: isIncome),
            ),
            const SizedBox(width: FrostedSpacing.sp2),
            _CategoryPill(
              category: category,
              isStale: isStale,
              onTap: onPickCategory,
            ),
          ],
        ),
        if (dateLabel != null || recurrenceLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: FrostedSpacing.sp1),
            child: _MetaLine(
              dateLabel: dateLabel,
              recurrenceLabel: recurrenceLabel,
              isStale: isStale,
              onPickDate: onPickDate,
            ),
          ),
      ],
    );
  }
}

/// Le montant du brouillon, dans les chiffres serif de la figure du mois : ce
/// qui se tape appartient déjà à l'app, pas à un formulaire.
class _DraftAmount extends StatelessWidget {
  static const double _integerFontSize = 30;
  static const double _decimalFontSize = 19;
  static const double _decimalAlpha = 0.65;

  final double amount;
  final bool isIncome;

  const _DraftAmount({required this.amount, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final color = isIncome
        ? context.financeColors.income
        : Theme.of(context).colorScheme.onSurface;

    return AnimatedAmount(
      amount: amount,
      builder: (context, value) {
        final parts = _split(value);
        return RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: AppTextStyles.displaySerifItalic(
              fontSize: _integerFontSize,
              height: 1,
              color: color,
            ),
            children: [
              TextSpan(text: '${isIncome ? '+ ' : ''}${parts.integer}'),
              TextSpan(
                text: ',${parts.decimals} €',
                style: AppTextStyles.displaySerifItalic(
                  fontSize: _decimalFontSize,
                  height: 1,
                  color: color.withValues(alpha: _decimalAlpha),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ({String integer, String decimals}) _split(double value) {
    final formatter = NumberFormat.decimalPattern('fr_FR')
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    final segments = formatter.format(value.abs()).split(',');

    return (
      integer: segments[0],
      decimals: segments.length > 1 ? segments[1] : '00',
    );
  }
}

/// Where the category lands. A hollow shimmering pill while the model reads,
/// an outline it does not fully stand behind, a filled tint once it does.
class _CategoryPill extends StatelessWidget {
  static const double _fillAlpha = 0.14;
  static const double _outlineAlpha = 0.5;
  static const double _pendingOutlineAlpha = 0.3;
  static const double _iconSize = 16;
  static const double _switchInScale = 0.9;

  final QuickAddCategoryPreview? category;
  final bool isStale;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.category,
    required this.isStale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final motion = context.frostedTokens.motion.snappy;
    final resolved = category;

    return AnimatedSwitcher(
      duration: motion.duration,
      switchInCurve: motion.curve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: _switchInScale,
            end: 1,
          ).animate(animation),
          child: child,
        ),
      ),
      child: resolved == null
          ? (isStale ? _pending(context) : const SizedBox.shrink())
          : QuickAddStale(
              key: ValueKey('${resolved.label}-${resolved.isUncertain}'),
              stale: isStale,
              child: _pill(context, resolved),
            ),
    );
  }

  Widget _pending(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return QuickAddShimmer(
      key: const ValueKey('pending'),
      child: _PillSurface(
        background: Colors.transparent,
        outline: scheme.onSurfaceVariant.withValues(
          alpha: _pendingOutlineAlpha,
        ),
        child: Icon(
          Symbols.auto_awesome_rounded,
          size: _iconSize,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, QuickAddCategoryPreview category) {
    final scheme = Theme.of(context).colorScheme;
    final uncertain = category.isUncertain;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FrostedRadius.full),
      child: _PillSurface(
        background: uncertain
            ? Colors.transparent
            : category.color.withValues(alpha: _fillAlpha),
        outline: uncertain
            ? category.color.withValues(alpha: _outlineAlpha)
            : Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: _iconSize, color: category.color),
            const SizedBox(width: FrostedSpacing.sp1),
            Text(
              category.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: uncertain ? scheme.onSurfaceVariant : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillSurface extends StatelessWidget {
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: FrostedSpacing.sp3,
    vertical: FrostedSpacing.sp2,
  );

  final Color background;
  final Color outline;
  final Widget child;

  const _PillSurface({
    required this.background,
    required this.outline,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(FrostedRadius.full),
        border: Border.all(color: outline),
      ),
      child: child,
    );
  }
}

/// Date and recurrence in the quiet mono register of the account line :
/// metadata, not peers of the amount.
class _MetaLine extends StatelessWidget {
  static const double _fontSize = 11;

  final String? dateLabel;
  final String? recurrenceLabel;
  final bool isStale;
  final VoidCallback onPickDate;

  const _MetaLine({
    required this.dateLabel,
    required this.recurrenceLabel,
    required this.isStale,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.mono(
      fontSize: _fontSize,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dateLabel != null)
          InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.circular(FrostedRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp1),
              child: Text(dateLabel!.toLowerCase(), style: style),
            ),
          ),
        if (dateLabel != null && recurrenceLabel != null)
          Text(' · ', style: style),
        if (recurrenceLabel != null)
          QuickAddStale(
            stale: isStale,
            child: Text(recurrenceLabel!.toLowerCase(), style: style),
          ),
      ],
    );
  }
}
