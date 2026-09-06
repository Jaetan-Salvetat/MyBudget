import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/core/values/category_display.dart';
import 'package:mybudget/data/provider/category_override_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/service/category_display_resolver.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';
import 'package:mybudget/ui/onboarding/models/onboarding_demo.dart';

class RecurrenceDemoView extends ConsumerStatefulWidget {
  const RecurrenceDemoView({required this.isActive, super.key});
  static const Duration monthDelay = Duration(milliseconds: 320);
  static const Duration monthFade = Duration(milliseconds: 380);

  final bool isActive;

  @override
  ConsumerState<RecurrenceDemoView> createState() => _RecurrenceDemoViewState();
}

class _RecurrenceDemoViewState extends ConsumerState<RecurrenceDemoView>
    with SingleTickerProviderStateMixin {
  static const RecurrenceDemo _demo = OnboardingDemo.recurrence;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration:
        RecurrenceDemoView.monthDelay * _demo.reportedMonths +
        RecurrenceDemoView.monthFade,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(RecurrenceDemoView oldWidget) {
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

  double _monthOpacity(int index) {
    final total = _controller.duration!.inMilliseconds;
    final start = RecurrenceDemoView.monthDelay.inMilliseconds * index / total;
    final end = start + RecurrenceDemoView.monthFade.inMilliseconds / total;

    return Interval(start, end.clamp(0.0, 1.0)).transform(_controller.value);
  }

  List<DateTime> _months() {
    final now = ref.read(clockProvider)();

    return List.generate(
      _demo.reportedMonths,
      (index) => DateTime(now.year, now.month + index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = ref
        .watch(categoryDisplayResolverProvider)
        .value
        ?.resolve(_demo.categorySlug);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Phrase(text: _demo.phrase),
          const SizedBox(height: FrostedSpacing.sp3),
          for (final (index, month) in _months().indexed) ...[
            if (index > 0) const SizedBox(height: FrostedSpacing.sp2),
            Opacity(
              opacity: _monthOpacity(index),
              child: _MonthRow(
                month: month,
                display: display,
                isFirst: index == 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Phrase extends StatelessWidget {
  const _Phrase({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.sp3,
          vertical: FrostedSpacing.sp2,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(FrostedRadius.full),
        ),
        child: Text(
          '« $text »',
          style: AppTextStyles.mono(
            fontSize: 11,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.month,
    required this.display,
    required this.isFirst,
  });
  static const double _pendingAlpha = 0.55;

  final DateTime month;
  final CategoryDisplay? display;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = display;
    final tone = resolved == null ? scheme.primary : Color(resolved.color);

    return Container(
      padding: const EdgeInsets.all(FrostedSpacing.sp2),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: isFirst ? 0.7 : 0.4),
        borderRadius: BorderRadius.circular(FrostedRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isFirst ? 0.6 : 0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              DateFormatter.shortMonth.format(month).toUpperCase(),
              style: AppTextStyles.eyebrowMono(
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isFirst ? 1 : _pendingAlpha,
                ),
              ),
            ),
          ),
          const SizedBox(width: FrostedSpacing.sp2),
          TransactionAvatar(
            color: tone,
            icon: CategoryDefaults.resolveIcon(
              resolved?.icon ?? CategoryDisplayResolver.uncategorizedIcon,
            ),
          ),
          const SizedBox(width: FrostedSpacing.sp3),
          Expanded(
            child: Text(
              OnboardingDemo.recurrence.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            _amount(),
            style: AppTextStyles.amount(color: context.financeColors.expense),
          ),
        ],
      ),
    );
  }

  String _amount() {
    final formatted = MoneyFormatter.format(OnboardingDemo.recurrence.amount);

    return '− $formatted';
  }
}
