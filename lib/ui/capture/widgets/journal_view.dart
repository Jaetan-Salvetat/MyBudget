import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/models/day_moment.dart';
import 'package:mybudget/ui/capture/models/journal_bucket.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';
import 'package:mybudget/ui/capture/widgets/day_gauge.dart';
import 'package:mybudget/ui/capture/widgets/journal_line.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

/// The past read backwards from now, in slices that coarsen as they age :
/// today flush against the top, then yesterday, the week, the month, and
/// every month before it. The list is what the page is about — the figure
/// above only says what it costs.
///
/// Rows are laid out flat and built on demand : a couple of years of history
/// is a couple of thousand lines, and none of the ones off screen are worth
/// an element.
class JournalView extends ConsumerStatefulWidget {
  /// How far the top of the list dissolves once it has been scrolled. At rest
  /// there is no fade at all : nothing has gone under the edge yet.
  static const double edgeFade = 40;

  static const String emptyMessage =
      'Rien encore. Dis-le comme ça te vient, ou photographie le ticket.';

  /// Past the first few lines the stagger stops : the rest is scrolled to,
  /// not opened onto.
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

  /// Months the reader has folded away. Everything opens open.
  final Set<String> _folded = <String>{};

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toggle(String label) {
    setState(() {
      if (!_folded.remove(label)) _folded.add(label);
    });
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _withToday(ref.watch(journalBucketsProvider));
    final resolver = ref.watch(categoryDisplayResolverProvider).value;
    final submissions = ref.watch(quickAddRecentSubmissionsProvider);
    final rows = _rows(context, buckets, resolver);

    return AnimatedBuilder(
      animation: _scroll,
      builder: (context, child) => ShaderMask(
        shaderCallback: _fade,
        blendMode: BlendMode.dstIn,
        child: child,
      ),
      child: ListView.builder(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(bottom: widget.bottomInset),
        itemCount: rows.length,
        itemBuilder: (context, index) =>
            _buildRow(context, rows[index], resolver, submissions),
      ),
    );
  }

  List<_Row> _rows(
    BuildContext context,
    List<JournalBucket> buckets,
    CategoryDisplayResolver? resolver,
  ) {
    final fallback = Theme.of(context).colorScheme.primary;
    final rows = <_Row>[];
    var line = 0;

    for (final bucket in buckets) {
      final folded = bucket.isCollapsible && _folded.contains(bucket.label);

      rows.add(
        _HeaderRow(
          bucket: bucket,
          isFirst: identical(bucket, buckets.first),
          expanded: !folded,
          onToggle: bucket.isCollapsible ? () => _toggle(bucket.label) : null,
        ),
      );
      if (folded) continue;

      final segments = GaugeSegment.forDay(bucket.entries, resolver, fallback);
      if (segments.isNotEmpty) rows.add(_GaugeRow(segments));
      if (bucket.entries.isEmpty) rows.add(const _EmptyRow());

      DayMoment? previousMoment;
      for (final entry in bucket.entries) {
        // Moments only ever cut a day up : anything coarser dates its lines.
        final moment = bucket.keepsTheHour && entry.hasTime
            ? DayMoment.ofHour(entry.at.hour)
            : null;
        if (moment != null && moment != previousMoment) {
          rows.add(_MomentRow(moment));
          previousMoment = moment;
        }

        rows.add(
          _LineRow(
            entry: entry,
            keepsTheHour: bucket.keepsTheHour,
            index: line++,
          ),
        );
      }
    }

    return rows;
  }

  Widget _buildRow(
    BuildContext context,
    _Row row,
    CategoryDisplayResolver? resolver,
    List<QuickAddSubmission> submissions,
  ) {
    switch (row) {
      case _HeaderRow row:
        return _BucketHeader(
          label: row.bucket.label,
          total: row.bucket.entries.isEmpty ? null : row.bucket.spent,
          topPadding: row.isFirst ? FrostedSpacing.sp0 : FrostedSpacing.sp5,
          expanded: row.expanded,
          onTap: row.onToggle,
        );

      case _GaugeRow row:
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            FrostedSpacing.sp2,
            FrostedSpacing.sp1,
            FrostedSpacing.sp2,
            FrostedSpacing.sp2,
          ),
          child: DayGauge(segments: row.segments),
        );

      case _EmptyRow():
        return Padding(
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
        );

      case _MomentRow row:
        return _MomentLabel(moment: row.moment);

      case _LineRow row:
        return _line(row, resolver, submissions);
    }
  }

  Widget _line(
    _LineRow row,
    CategoryDisplayResolver? resolver,
    List<QuickAddSubmission> submissions,
  ) {
    final entry = row.entry;
    final fresh = submissions
        .where(
          (submission) => entry.sameTransaction(submission.type, submission.id),
        )
        .firstOrNull;

    final line = JournalLine(
      entry: entry,
      category: entry.categorySlug == null
          ? null
          : resolver?.resolve(entry.categorySlug!),
      keepsTheHour: row.keepsTheHour,
      isFresh: fresh != null,
      onUndo: fresh == null ? null : () => _undo(ref, fresh),
    );

    if (row.index >= JournalView.staggeredLines) return line;
    return _Rise(index: row.index, child: line);
  }

  /// Today always opens the list, even with nothing on it : the page has to
  /// say where "now" is before it says what came before.
  List<JournalBucket> _withToday(List<JournalBucket> buckets) {
    if (buckets.isNotEmpty && buckets.first.kind == JournalBucketKind.today) {
      return buckets;
    }

    return [
      JournalBucket(
        kind: JournalBucketKind.today,
        anchor: dayOnly(DateTime.now()),
        entries: const [],
      ),
      ...buckets,
    ];
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

sealed class _Row {
  const _Row();
}

class _HeaderRow extends _Row {
  final JournalBucket bucket;
  final bool isFirst;
  final bool expanded;
  final VoidCallback? onToggle;

  const _HeaderRow({
    required this.bucket,
    required this.isFirst,
    required this.expanded,
    required this.onToggle,
  });
}

class _GaugeRow extends _Row {
  final List<GaugeSegment> segments;

  const _GaugeRow(this.segments);
}

class _EmptyRow extends _Row {
  const _EmptyRow();
}

class _MomentRow extends _Row {
  final DayMoment moment;

  const _MomentRow(this.moment);
}

class _LineRow extends _Row {
  final JournalEntry entry;
  final bool keepsTheHour;
  final int index;

  const _LineRow({
    required this.entry,
    required this.keepsTheHour,
    required this.index,
  });
}

class _BucketHeader extends StatelessWidget {
  final String label;
  final double? total;
  final double topPadding;
  final bool expanded;
  final VoidCallback? onTap;

  const _BucketHeader({
    required this.label,
    required this.topPadding,
    required this.expanded,
    required this.onTap,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motion = context.frostedTokens.motion.snappy;
    final amount = total;

    final row = Padding(
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp2,
        topPadding,
        FrostedSpacing.sp2,
        FrostedSpacing.sp1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: Eyebrow(label)),
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(left: FrostedSpacing.sp1),
              child: AnimatedRotation(
                turns: expanded ? 0.25 : 0,
                duration: motion.duration,
                curve: motion.curve,
                child: Icon(
                  Symbols.chevron_right_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
          const Spacer(),
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

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FrostedRadius.md),
        child: row,
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

/// The first lines land one after another rather than all at once : the eye
/// follows the list instead of meeting a block.
class _Rise extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 460);
  static const Duration step = Duration(milliseconds: 45);
  static const double travel = 10;

  final int index;
  final Widget child;

  const _Rise({required this.index, required this.child});

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
    _start = Timer(_Rise.step * widget.index, () {
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
