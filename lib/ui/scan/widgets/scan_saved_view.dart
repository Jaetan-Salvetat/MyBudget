import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/core/values/category_display.dart';
import 'package:mybudget/data/model/receipt_scan_result_model.dart';

class ScanSavedView extends StatefulWidget {
  const ScanSavedView({
    required this.result,
    required this.resolve,
    required this.onDone,
    required this.onDiscard,
    super.key,
  });
  static const String doneLabel = 'Terminé';
  static const String discardLabel = 'Annuler';

  static const Duration markDuration = Duration(milliseconds: 520);
  static const Duration stagger = Duration(milliseconds: 110);
  static const double markSize = 56;

  static String titleOf(int count) =>
      count > 1 ? '$count dépenses enregistrées' : '1 dépense enregistrée';

  final ReceiptScanResultModel result;
  final CategoryDisplay? Function(String? slug) resolve;
  final VoidCallback onDone;
  final VoidCallback onDiscard;

  @override
  State<ScanSavedView> createState() => _ScanSavedViewState();
}

class _ScanSavedViewState extends State<ScanSavedView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _stepAt(int rank) {
    const span = 0.28;
    final start = (rank * 0.16).clamp(0.0, 1 - span);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, start + span, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = widget.result.groupedByCategory;
    final store = widget.result.storeName;
    final date = DateFormatter.longDate.format(widget.result.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _Mark(controller: _controller)),
          const SizedBox(height: FrostedSpacing.sp5),
          _Rise(
            animation: _stepAt(1),
            child: Center(
              child: Text(
                MoneyFormatter.format(widget.result.itemsTotal),
                style: AppTextStyles.displaySerifItalic(
                  fontSize: 40,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: FrostedSpacing.sp2),
          _Rise(
            animation: _stepAt(2),
            child: Center(
              child: Text(
                ScanSavedView.titleOf(groups.length),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: FrostedSpacing.sp1),
          _Rise(
            animation: _stepAt(2),
            child: Center(
              child: Text(
                store == null ? 'Le $date' : '$store, le $date',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: FrostedSpacing.sp5),
          for (final (index, group) in groups.indexed)
            _Rise(
              animation: _stepAt(3 + index),
              child: _GroupLine(
                group: group,
                category: widget.resolve(group.slug),
              ),
            ),
          const SizedBox(height: FrostedSpacing.sp6),
          _Rise(
            animation: _stepAt(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FrostedButton.filled(
                  label: ScanSavedView.doneLabel,
                  onPressed: widget.onDone,
                ),
                const SizedBox(height: FrostedSpacing.sp1),
                FrostedButton.text(
                  label: ScanSavedView.discardLabel,
                  onPressed: widget.onDiscard,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.controller});
  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    final color = context.financeColors.income;
    final pop = CurvedAnimation(
      parent: controller,
      curve: const Interval(0, 0.4, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: pop,
      child: FadeTransition(
        opacity: pop,
        child: Container(
          width: ScanSavedView.markSize,
          height: ScanSavedView.markSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(Symbols.check_rounded, size: 24, color: color),
        ),
      ),
    );
  }
}

class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _GroupLine extends StatelessWidget {
  const _GroupLine({required this.group, required this.category});
  final ScannedExpenseGroup group;
  final CategoryDisplay? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp1),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: category == null
                  ? theme.colorScheme.onSurfaceVariant
                  : Color(category!.color),
            ),
          ),
          const SizedBox(width: FrostedSpacing.sp3),
          Flexible(
            child: Text(
              category?.label ?? group.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Text(
            MoneyFormatter.format(group.total),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
