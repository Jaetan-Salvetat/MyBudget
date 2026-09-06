import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/onboarding/models/onboarding_demo.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

class ReceiptDemoView extends ConsumerStatefulWidget {
  static const Duration lineRead = Duration(milliseconds: 420);

  final bool isActive;

  const ReceiptDemoView({required this.isActive, super.key});

  @override
  ConsumerState<ReceiptDemoView> createState() => _ReceiptDemoViewState();
}

class _ReceiptDemoViewState extends ConsumerState<ReceiptDemoView>
    with SingleTickerProviderStateMixin {
  static const ReceiptDemo _demo = OnboardingDemo.receipt;
  static const double _paperWidth = 218;
  static const double _highlightAlpha = 0.12;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ReceiptDemoView.lineRead * _demo.lines.length,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(ReceiptDemoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPlayback();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncPlayback() {
    if (!widget.isActive || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }

    _controller.forward(from: 0);
  }

  int get _readingIndex =>
      (_controller.value * _demo.lines.length).floor();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolver = ref.watch(categoryDisplayResolverProvider).value;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: _paperWidth,
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.sp3,
          vertical: FrostedSpacing.sp4,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(FrostedRadius.sm),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _demo.store,
              textAlign: TextAlign.center,
              style: AppTextStyles.eyebrowMono(color: scheme.onSurface),
            ),
            const SizedBox(height: FrostedSpacing.sp1),
            Text(
              DateFormat('dd/MM/yyyy', 'fr_FR').format(DateTime.now()),
              textAlign: TextAlign.center,
              style: AppTextStyles.mono(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FrostedSpacing.sp3),
            const FrostedDivider(),
            const SizedBox(height: FrostedSpacing.sp2),
            for (final (index, line) in _demo.lines.indexed)
              _ReceiptLine(
                line: line,
                display: resolver?.resolve(line.categorySlug),
                isReading: index == _readingIndex,
                isRead: index < _readingIndex,
                highlightAlpha: _highlightAlpha,
              ),
            const SizedBox(height: FrostedSpacing.sp2),
            const FrostedDivider(),
            const SizedBox(height: FrostedSpacing.sp2),
            _TotalLine(total: _demo.total),
          ],
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  static const double _pipSize = 7;

  final ReceiptDemoLine line;
  final CategoryDisplay? display;
  final bool isReading;
  final bool isRead;
  final double highlightAlpha;

  const _ReceiptLine({
    required this.line,
    required this.display,
    required this.isReading,
    required this.isRead,
    required this.highlightAlpha,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = AppTextStyles.mono(
      fontSize: 10.5,
      color: scheme.onSurfaceVariant,
    );
    final resolved = display;
    final tone = resolved == null ? scheme.primary : Color(resolved.color);

    return AnimatedContainer(
      duration: ReceiptDemoView.lineRead,
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.sp1,
        vertical: FrostedSpacing.sp1,
      ),
      decoration: BoxDecoration(
        color: isReading
            ? scheme.primary.withValues(alpha: highlightAlpha)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(FrostedRadius.xs),
      ),
      child: Row(
        children: [
          AnimatedOpacity(
            duration: ReceiptDemoView.lineRead,
            opacity: isReading || isRead ? 1 : 0,
            child: Container(
              width: _pipSize,
              height: _pipSize,
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: FrostedSpacing.sp2),
          Expanded(child: Text(line.label, style: style)),
          Text(_amount(line.amount), style: style),
        ],
      ),
    );
  }

  String _amount(double value) => NumberFormat.decimalPatternDigits(
    locale: 'fr_FR',
    decimalDigits: 2,
  ).format(value);
}

class _TotalLine extends StatelessWidget {
  final double total;

  const _TotalLine({required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = AppTextStyles.mono(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    );

    return Row(
      children: [
        Expanded(child: Text('TOTAL', style: style)),
        Text(
          NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(total),
          style: style,
        ),
      ],
    );
  }
}
