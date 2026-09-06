import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/models/scanned_item_model.dart';
import 'package:mybudget/ui/scan/widgets/scan_motion.dart';

class ScanItemRow extends StatefulWidget {
  const ScanItemRow({
    required this.item,
    required this.category,
    this.highlighted = false,
    required this.onNameChanged,
    required this.onAmountChanged,
    required this.onPickCategory,
    super.key,
  });
  static const String unrankedLabel = 'Ranger cet article';
  static const String toConfirmSuffix = ' · à confirmer';
  static const String confirmedSuffix = ' · confirmé';

  static const double extent = 62;

  static const Duration highlightFade = Duration(milliseconds: 900);

  static const Duration stateChange = ScanMotion.swap;

  static const double pipSize = 7;
  static const double pipTapSize = 28;

  final ScannedItemModel item;
  final CategoryDisplay? category;
  final bool highlighted;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback onPickCategory;

  @override
  State<ScanItemRow> createState() => _ScanItemRowState();
}

class _ScanItemRowState extends State<ScanItemRow> {
  late final TextEditingController _name = TextEditingController(
    text: widget.item.name,
  );
  late final TextEditingController _amount = TextEditingController(
    text: _formatAmount(widget.item.effectiveAmount),
  );

  @override
  void didUpdateWidget(ScanItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.name != oldWidget.item.name &&
        _name.text != widget.item.name) {
      _name.text = widget.item.name;
    }
    final amount = _formatAmount(widget.item.effectiveAmount);
    if (widget.item.effectiveAmount != oldWidget.item.effectiveAmount &&
        _amount.text != amount) {
      _amount.text = amount;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  static String _formatAmount(double value) =>
      MoneyFormatter.formatPlain(value);

  void _submitName() {
    final value = _name.text.trim();
    if (value.isEmpty) {
      _name.text = widget.item.name;
      return;
    }
    if (value == widget.item.name) return;
    widget.onNameChanged(value);
  }

  void _submitAmount() {
    final parsed = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      _amount.text = _formatAmount(widget.item.effectiveAmount);
      return;
    }
    if (parsed == widget.item.effectiveAmount) return;
    widget.onAmountChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: ScanItemRow.highlightFade,
      curve: Curves.easeOut,
      height: ScanItemRow.extent,
      color: widget.highlighted
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Pip(item: widget.item, category: widget.category),
          const SizedBox(width: FrostedSpacing.sp2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.done,
                  style: theme.textTheme.bodyMedium,
                  decoration: const InputDecoration.collapsed(hintText: ''),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  onEditingComplete: _submitName,
                  onSubmitted: (_) => _submitName(),
                ),
                _CategoryLine(
                  item: widget.item,
                  category: widget.category,
                  onTap: widget.onPickCategory,
                ),
              ],
            ),
          ),
          const SizedBox(width: FrostedSpacing.sp2),
          _AmountField(
            controller: _amount,
            discount: widget.item.discount,
            onSubmit: _submitAmount,
          ),
        ],
      ),
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.item, required this.category});
  final ScannedItemModel item;
  final CategoryDisplay? category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = category == null ? scheme.primary : Color(category!.color);

    final BoxDecoration decoration;
    if (!item.isRanked) {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primary, width: 1.4),
      );
    } else if (item.isCategoryUncertain) {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.22),
            spreadRadius: 3.5,
          ),
        ],
      );
    } else if (item.confirmedByUser) {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: scheme.surface, spreadRadius: 2.5),
          BoxShadow(color: color, spreadRadius: 4),
        ],
      );
    } else {
      decoration = BoxDecoration(shape: BoxShape.circle, color: color);
    }

    return SizedBox(
      width: ScanItemRow.pipTapSize,
      height: ScanItemRow.pipTapSize,
      child: Center(
        child: AnimatedContainer(
          duration: ScanItemRow.stateChange,
          width: ScanItemRow.pipSize,
          height: ScanItemRow.pipSize,
          decoration: decoration,
        ),
      ),
    );
  }
}

class _CategoryLine extends StatelessWidget {
  const _CategoryLine({
    required this.item,
    required this.category,
    required this.onTap,
  });
  final ScannedItemModel item;
  final CategoryDisplay? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final String label;
    final Color color;
    final FontWeight weight;

    if (!item.isRanked) {
      label = ScanItemRow.unrankedLabel;
      color = scheme.primary;
      weight = FontWeight.w500;
    } else if (item.isCategoryUncertain) {
      label = '${category?.label ?? ''}${ScanItemRow.toConfirmSuffix}';
      color = context.financeColors.expense;
      weight = FontWeight.w500;
    } else if (item.confirmedByUser) {
      label = '${category?.label ?? ''}${ScanItemRow.confirmedSuffix}';
      color = scheme.onSurfaceVariant;
      weight = FontWeight.w400;
    } else {
      label = category?.label ?? '';
      color = scheme.onSurfaceVariant;
      weight = FontWeight.w400;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FrostedRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.sp1,
          vertical: 1,
        ),
        child: ScanSwap(
          child: Text(
            label,
            key: ValueKey(label),
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: weight,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.discount,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final double discount;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (discount > 0)
          Text(
            '${MoneyFormatter.minusSign}${MoneyFormatter.formatPlain(discount)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.financeColors.income,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        SizedBox(
          width: 68,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.end,
            textInputAction: TextInputAction.done,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: style,
            decoration: const InputDecoration.collapsed(hintText: ''),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onEditingComplete: onSubmit,
            onSubmitted: (_) => onSubmit(),
          ),
        ),
      ],
    );
  }
}
