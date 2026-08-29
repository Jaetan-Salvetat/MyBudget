import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/models/day_moment.dart';
import 'package:mybudget/ui/capture/models/journal_day.dart';
import 'package:mybudget/ui/capture/widgets/day_gauge.dart';
import 'package:mybudget/ui/capture/widgets/journal_line.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

/// The month read backwards from now : today at the top, flush against the
/// first line, then every day the month has recorded. The list is what the
/// page is about — the figure above only says what it costs.
class JournalView extends ConsumerStatefulWidget {
  /// How far the top of the list dissolves once it has been scrolled. At rest
  /// there is no fade at all : nothing has gone under the edge yet.
  static const double edgeFade = 40;

  static const String emptyMessage =
      'Rien encore. Dis-le comme ça te vient, ou photographie le ticket.';

  /// Past the first few lines the stagger stops : the rest of the month is
  /// scrolled to, not opened onto.
  static const int staggeredLines = 8;

  /// Room left under the last line so it slides beneath the glass dock
  /// instead of stopping short of it.
  final double bottomInset;

  const JournalView({required this.bottomInset, super.key});

  @override
  ConsumerState<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends ConsumerState<JournalView> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysWithToday(ref.watch(monthJournalProvider));
    final resolver = ref.watch(categoryDisplayResolverProvider).value;
    final submissions = ref.watch(quickAddRecentSubmissionsProvider);

    var line = 0;

    return AnimatedBuilder(
      animation: _scroll,
      builder: (context, child) => ShaderMask(
        shaderCallback: _fade,
        blendMode: BlendMode.dstIn,
        child: child,
      ),
      child: SingleChildScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: widget.bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final day in days)
              _DaySection(
                day: day,
                resolver: resolver,
                submissions: submissions,
                isFirst: identical(day, days.first),
                firstLineIndex: (line += day.entries.length) -
                    day.entries.length,
                onUndo: (submission) => _undo(ref, submission),
              ),
          ],
        ),
      ),
    );
  }

  /// Today always opens the list, even with nothing on it : the page has to
  /// say where "now" is before it says what came before.
  List<JournalDay> _daysWithToday(List<JournalDay> days) {
    final today = dayOnly(DateTime.now());
    if (days.isNotEmpty && days.first.isSameDay(today)) return days;

    return [JournalDay(day: today, entries: const []), ...days];
  }

  /// The edge only dissolves what has scrolled past it. Nothing has, at rest,
  /// so the first line stays whole and hard against the top.
  Shader _fade(Rect bounds) {
    final scrolled = _scroll.hasClients ? _scroll.offset : 0.0;
    final extent = scrolled.clamp(0.0, JournalView.edgeFade);
    if (extent < 1) {
      return const LinearGradient(
        colors: [Colors.black, Colors.black],
      ).createShader(bounds);
    }

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Colors.transparent, Colors.black],
      stops: [0, (extent / bounds.height).clamp(0.0, 1.0)],
    ).createShader(bounds);
  }

  Future<void> _undo(WidgetRef ref, QuickAddSubmission submission) async {
    ref.read(quickAddRecentSubmissionsProvider.notifier).dismiss(submission);
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(quickAddProvider.notifier).undo(submission);
  }
}

class _DaySection extends StatelessWidget {
  final JournalDay day;
  final CategoryDisplayResolver? resolver;
  final List<QuickAddSubmission> submissions;

  /// Nothing stands above the first day : its header sits flush against the
  /// top of the list, never on a cushion of empty space.
  final bool isFirst;

  final int firstLineIndex;
  final ValueChanged<QuickAddSubmission> onUndo;

  const _DaySection({
    required this.day,
    required this.resolver,
    required this.submissions,
    required this.isFirst,
    required this.firstLineIndex,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final segments = GaugeSegment.forDay(
      day.entries,
      resolver,
      Theme.of(context).colorScheme.primary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayHeader(
          label: _label(day.day),
          total: day.entries.isEmpty ? null : day.spent,
          topPadding: isFirst ? FrostedSpacing.sp0 : FrostedSpacing.sp4,
        ),
        if (segments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FrostedSpacing.sp2,
              FrostedSpacing.sp1,
              FrostedSpacing.sp2,
              FrostedSpacing.sp2,
            ),
            child: DayGauge(segments: segments),
          ),
        if (day.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FrostedSpacing.sp2,
              FrostedSpacing.sp2,
              FrostedSpacing.sp2,
              FrostedSpacing.sp5,
            ),
            child: Text(
              JournalView.emptyMessage,
              style: TextStyle(
                fontSize: 13.5,
                height: 20 / 13.5,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.62),
              ),
            ),
          ),
        ..._lines(),
      ],
    );
  }

  List<Widget> _lines() {
    final widgets = <Widget>[];
    DayMoment? previousMoment;

    for (var index = 0; index < day.entries.length; index++) {
      final entry = day.entries[index];
      final moment = entry.hasTime ? DayMoment.ofHour(entry.at.hour) : null;

      if (moment != null && moment != previousMoment) {
        widgets.add(_MomentLabel(moment: moment));
        previousMoment = moment;
      }

      final fresh = submissions
          .where((submission) => entry.sameTransaction(submission.type, submission.id))
          .firstOrNull;

      widgets.add(
        _Rise(
          index: firstLineIndex + index,
          key: ValueKey('${entry.type}-${entry.id}'),
          child: JournalLine(
            entry: entry,
            category: entry.categorySlug == null
                ? null
                : resolver?.resolve(entry.categorySlug!),
            isFresh: fresh != null,
            onUndo: fresh == null ? null : () => onUndo(fresh),
          ),
        ),
      );
    }

    return widgets;
  }

  /// The two days that have a word get it ; the rest of the month is dated.
  static String _label(DateTime day) {
    final today = dayOnly(DateTime.now());
    final days = today.difference(day).inDays;
    if (days == 0) return 'Aujourd\'hui';
    if (days == 1) return 'Hier';

    return DateFormat('EEEE d MMMM', 'fr_FR').format(day);
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  final double? total;
  final double topPadding;

  const _DayHeader({
    required this.label,
    required this.topPadding,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = total;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp2,
        topPadding,
        FrostedSpacing.sp2,
        FrostedSpacing.sp1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Eyebrow(label)),
          if (amount != null)
            Text(
              _amountLabel(amount),
              style: AppTextStyles.displaySerifItalic(
                fontSize: 15,
                height: 1.1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }

  String _amountLabel(double amount) {
    final formatted = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    ).format(amount.abs());
    return amount < 0 ? '+ $formatted' : '− $formatted';
  }
}

class _MomentLabel extends StatelessWidget {
  final DayMoment moment;

  const _MomentLabel({required this.moment});

  static const double _opacity = 0.42;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: _opacity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FrostedSpacing.sp2,
        FrostedSpacing.sp3,
        FrostedSpacing.sp2,
        FrostedSpacing.sp1,
      ),
      child: Row(
        children: [
          Text(
            moment.label.toUpperCase(),
            style: AppTextStyles.mono(
              fontSize: 9,
              lineHeight: 12,
              letterSpacingEm: 0.12,
              color: color,
            ),
          ),
          const SizedBox(width: FrostedSpacing.sp3),
          Expanded(child: Divider(height: 1, color: color)),
        ],
      ),
    );
  }
}

/// Lines land one after another rather than all at once : the eye follows the
/// day instead of meeting a block.
class _Rise extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 460);
  static const Duration step = Duration(milliseconds: 45);
  static const double travel = 10;

  final int index;
  final Widget child;

  const _Rise({required this.index, required this.child, super.key});

  @override
  State<_Rise> createState() => _RiseState();
}

class _RiseState extends State<_Rise> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _Rise.duration,
  );

  Timer? _start;

  @override
  void initState() {
    super.initState();
    final delay =
        _Rise.step * widget.index.clamp(0, JournalView.staggeredLines).toInt();
    _start = Timer(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    final curve = CurvedAnimation(
      parent: _controller,
      curve: context.frostedTokens.motion.fluid.curve,
    );

    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, _Rise.travel * (1 - curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
