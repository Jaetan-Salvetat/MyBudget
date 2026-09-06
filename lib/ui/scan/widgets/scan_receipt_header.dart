import 'dart:ui' show lerpDouble;
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scan_read_progress_model.dart';
import 'package:mybudget/ui/common/widgets/animated_amount.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';
import 'package:mybudget/ui/scan/widgets/scan_motion.dart';
import 'package:mybudget/ui/scan/widgets/scan_reveal.dart';

class ScanReceiptHeader extends StatefulWidget {
  const ScanReceiptHeader({
    required this.result,
    required this.reveal,
    required this.now,
    this.progress = const ScanReadProgress(),
    required this.onStoreChanged,
    required this.onPickDate,
    required this.onFillGap,
    super.key,
  });
  static const String readingLabel = 'Lecture du ticket';
  static const String verifiedLabel = 'Montants vérifiés sur le total';
  static const String storeFallback = 'Ticket';

  static const double height = 148;
  static const double readingAmountSize = 54;
  static const double reviewAmountSize = 34;

  static const Duration arrival = ScanMotion.settle;

  final ReceiptScanResultModel? result;

  final ScanReadProgress progress;
  final DateTime now;
  final Animation<double> reveal;
  final ValueChanged<String> onStoreChanged;
  final VoidCallback onPickDate;
  final VoidCallback onFillGap;

  @override
  State<ScanReceiptHeader> createState() => _ScanReceiptHeaderState();
}

class _ScanReceiptHeaderState extends State<ScanReceiptHeader> {
  String? get _store => widget.result?.storeName ?? widget.progress.storeName;

  DateTime? get _date => widget.result?.date ?? widget.progress.date;

  double? get _amount =>
      widget.result?.itemsTotal ?? widget.progress.printedTotal;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.reveal,
      builder: (context, _) {
        final t = ScanReveal.headerProgressOf(widget.reveal.value);

        return SizedBox(
          height: ScanReceiptHeader.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Identity(
                  store: _store,
                  editable: widget.result != null && t >= 1,
                  progress: t,
                  onStoreChanged: widget.onStoreChanged,
                ),
                const SizedBox(height: FrostedSpacing.sp1),
                _Amount(amount: _amount, progress: t),
                const SizedBox(height: FrostedSpacing.sp2),
                _Meta(
                  date: _date,
                  now: widget.now,
                  result: widget.result,
                  progress: t,
                  onPickDate: widget.onPickDate,
                  onFillGap: widget.onFillGap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Breathing extends StatefulWidget {
  const _Breathing({required this.child});
  static const Duration period = Duration(milliseconds: 1400);
  static const double floor = 0.42;

  final Widget child;

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _Breathing.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = MediaQuery.maybeDisableAnimationsOf(context) != true;
    if (animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
    if (!animate && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: _Breathing.floor,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

Alignment headerAlignmentOf(double progress) =>
    Alignment.lerp(Alignment.center, Alignment.centerLeft, progress)!;

class _Identity extends StatefulWidget {
  const _Identity({
    required this.store,
    required this.editable,
    required this.progress,
    required this.onStoreChanged,
  });
  final String? store;
  final bool editable;
  final double progress;
  final ValueChanged<String> onStoreChanged;

  @override
  State<_Identity> createState() => _IdentityState();
}

class _IdentityState extends State<_Identity> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.store ?? '',
  );

  @override
  void didUpdateWidget(_Identity oldWidget) {
    super.didUpdateWidget(oldWidget);
    final store = widget.store ?? '';
    if (store != (oldWidget.store ?? '') && _controller.text != store) {
      _controller.text = store;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      _controller.text = widget.store ?? '';
      return;
    }
    if (value == widget.store) return;
    widget.onStoreChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (!widget.editable) {
      final read = widget.store != null;
      return Stack(
        alignment: Alignment.center,
        children: [
          ScanSettle(
            visible: !read,
            child: const _Breathing(
              child: Eyebrow(ScanReceiptHeader.readingLabel),
            ),
          ),
          ScanSettle(
            visible: read,
            child: Align(
              alignment: headerAlignmentOf(widget.progress),
              child: Text(widget.store ?? '', style: style),
            ),
          ),
        ],
      );
    }

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.done,
      style: style,
      decoration: const InputDecoration.collapsed(
        hintText: ScanReceiptHeader.storeFallback,
      ),
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      onEditingComplete: _submit,
      onSubmitted: (_) => _submit(),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.amount, required this.progress});
  final double? amount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = lerpDouble(
      ScanReceiptHeader.readingAmountSize,
      ScanReceiptHeader.reviewAmountSize,
      progress,
    )!;
    final style = AppTextStyles.displaySerifItalic(
      fontSize: size,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Align(
      alignment: headerAlignmentOf(progress),
      child: AnimatedAmount(
        amount: amount ?? 0,
        builder: (context, value) => Text(
          amount == null ? '—' : MoneyFormatter.format(value),
          style: style,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.date,
    required this.now,
    required this.result,
    required this.progress,
    required this.onPickDate,
    required this.onFillGap,
  });
  final DateTime? date;
  final DateTime now;
  final ReceiptScanResultModel? result;
  final double progress;
  final VoidCallback onPickDate;
  final VoidCallback onFillGap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final scan = result;
    final read = date ?? now;

    return Align(
      alignment: headerAlignmentOf(progress),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedSpacing.sp2,
        children: [
          IgnorePointer(
            ignoring: date == null,
            child: ScanSettle(
              visible: date != null,
              child: _Tap(
                onTap: onPickDate,
                child: ScanSwap(
                  child: Text(
                    DateFormatter.longDate.format(read),
                    key: ValueKey(read),
                    style: style,
                  ),
                ),
              ),
            ),
          ),
          if (scan != null && scan.printedTotal != null)
            Opacity(
              opacity: progress,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: FrostedSpacing.sp2,
                children: [
                  const _Separator(),
                  ScanSwap(
                    child: scan.hasGap
                        ? _Tap(
                            key: const ValueKey('gap'),
                            onTap: onFillGap,
                            child: Text(
                              'écart ${MoneyFormatter.format(scan.gap!)}',
                              style: style?.copyWith(
                                color: context.financeColors.expense,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : Row(
                            key: const ValueKey('verified'),
                            mainAxisSize: MainAxisSize.min,
                            spacing: FrostedSpacing.sp1,
                            children: [
                              Icon(
                                Symbols.check_rounded,
                                size: 14,
                                color: context.financeColors.income,
                              ),
                              Text(
                                ScanReceiptHeader.verifiedLabel,
                                style: style?.copyWith(
                                  color: context.financeColors.income,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.5,
      height: 2.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Tap extends StatelessWidget {
  const _Tap({required this.onTap, required this.child, super.key});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FrostedRadius.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp1),
        child: child,
      ),
    );
  }
}
