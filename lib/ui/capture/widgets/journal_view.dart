import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/rules/recurrence_rules.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/data/model/quick_add_submission_model.dart';
import 'package:mybudget/data/provider/category_override_provider.dart';
import 'package:mybudget/data/provider/loan_queries.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/provider/quick_add_recent_submissions_provider.dart';
import 'package:mybudget/data/service/category_display_resolver.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/models/day_moment.dart';
import 'package:mybudget/ui/capture/models/journal_bucket.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';
import 'package:mybudget/ui/capture/quick_add_provider.dart';
import 'package:mybudget/ui/capture/widgets/day_gauge.dart';
import 'package:mybudget/ui/capture/widgets/journal_landing.dart';
import 'package:mybudget/ui/capture/widgets/journal_line.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';
import 'package:mybudget/ui/loans/screens/loan_details_screen.dart';
import 'package:mybudget/ui/transaction_details/screens/expense_details_screen.dart';
import 'package:mybudget/ui/transaction_details/screens/revenue_details_screen.dart';

class JournalView extends ConsumerStatefulWidget {
  const JournalView({required this.bottomInset, super.key});
  static const double edgeFade = 40;

  static const String emptyMessage =
      'Rien encore. Dis-le comme ça te vient, ou photographie le ticket.';

  static const int staggeredLines = 8;

  final double bottomInset;

  static LinearGradient edgeGradient({
    required double scrolled,
    required double height,
  }) {
    final top = (scrolled.clamp(0.0, edgeFade) / height).clamp(0.0, 1.0);

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Colors.transparent, Colors.black, Colors.black],
      stops: [0, top, 1],
    );
  }

  @override
  ConsumerState<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends ConsumerState<JournalView> {
  final ScrollController _scroll = ScrollController();

  final Set<String> _folded = <String>{};

  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _opened = true);
  }

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

      final segments = DayGauge.segmentsForDay(
        bucket.entries,
        resolver,
        fallback,
      );
      if (segments.isNotEmpty) rows.add(_GaugeRow(segments));
      if (bucket.entries.isEmpty) rows.add(const _EmptyRow());

      DayMoment? previousMoment;
      for (final entry in bucket.entries) {
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
      case final _HeaderRow row:
        return _BucketHeader(
          label: row.bucket.label,
          total: row.bucket.entries.isEmpty ? null : row.bucket.spent,
          topPadding: row.isFirst ? FrostedSpacing.sp0 : FrostedSpacing.sp5,
          expanded: row.expanded,
          onTap: row.onToggle,
        );

      case final _GaugeRow row:
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

      case final _MomentRow row:
        return _MomentLabel(moment: row.moment);

      case final _LineRow row:
        return _line(row, resolver, submissions);
    }
  }

  void _openDetails(JournalEntry entry) {
    switch (entry.source) {
      case JournalEntrySource.expense:
        ExpenseDetailsScreen.push(
          context: context,
          expenseId: entry.id,
          isCurrentMonth: _landsThisMonth(entry),
        );
      case JournalEntrySource.revenue:
        RevenueDetailsScreen.push(
          context: context,
          revenueId: entry.id,
          isCurrentMonth: _landsThisMonth(entry),
        );
      case JournalEntrySource.loan:
        _openLoanDetails(entry.id);
    }
  }

  bool _landsThisMonth(JournalEntry entry) {
    final now = ref.read(clockProvider)();
    return entry.at.year == now.year && entry.at.month == now.month;
  }

  void _openLoanDetails(int loanId) {
    final loan = ref
        .read(activeLoansProvider)
        .where((candidate) => candidate.id == loanId)
        .firstOrNull;
    if (loan == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LoanDetailsScreen(loan: loan)),
    );
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
      onTap: () => _openDetails(entry),
    );

    final landing = submissions.isNotEmpty && _isLast(entry, submissions);
    if (landing) {
      return JournalLanding(
        key: ValueKey<String>(
          '${entry.source.name}-${entry.id}-${entry.at.microsecondsSinceEpoch}',
        ),
        child: line,
      );
    }

    if (_opened || row.index >= JournalView.staggeredLines) return line;

    return _Rise(index: row.index, child: line);
  }

  bool _isLast(JournalEntry entry, List<QuickAddSubmission> submissions) {
    final last = submissions.last;
    return entry.sameTransaction(last.type, last.id);
  }

  List<JournalBucket> _withToday(List<JournalBucket> buckets) {
    if (buckets.isNotEmpty && buckets.first.kind == JournalBucketKind.today) {
      return buckets;
    }

    return [
      JournalBucket(
        kind: JournalBucketKind.today,
        anchor: dayOnly(ref.read(clockProvider)()),
        entries: const [],
      ),
      ...buckets,
    ];
  }

  Shader _fade(Rect bounds) => JournalView.edgeGradient(
    scrolled: _scroll.hasClients ? _scroll.offset : 0,
    height: bounds.height,
  ).createShader(bounds);

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
  const _HeaderRow({
    required this.bucket,
    required this.isFirst,
    required this.expanded,
    required this.onToggle,
  });
  final JournalBucket bucket;
  final bool isFirst;
  final bool expanded;
  final VoidCallback? onToggle;
}

class _GaugeRow extends _Row {
  const _GaugeRow(this.segments);
  final List<FrostedBarSegment> segments;
}

class _EmptyRow extends _Row {
  const _EmptyRow();
}

class _MomentRow extends _Row {
  const _MomentRow(this.moment);
  final DayMoment moment;
}

class _LineRow extends _Row {
  const _LineRow({
    required this.entry,
    required this.keepsTheHour,
    required this.index,
  });
  final JournalEntry entry;
  final bool keepsTheHour;
  final int index;
}

class _BucketHeader extends StatelessWidget {
  const _BucketHeader({
    required this.label,
    required this.topPadding,
    required this.expanded,
    required this.onTap,
    this.total,
  });
  final String label;
  final double? total;
  final double topPadding;
  final bool expanded;
  final VoidCallback? onTap;

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
    final formatted = MoneyFormatter.format(amount.abs());
    return amount < 0 ? '+ $formatted' : '− $formatted';
  }
}

class _MomentLabel extends StatelessWidget {
  const _MomentLabel({required this.moment});
  final DayMoment moment;

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

class _Rise extends StatefulWidget {
  const _Rise({required this.index, required this.child});
  static const Duration duration = Duration(milliseconds: 460);
  static const Duration step = Duration(milliseconds: 45);
  static const double travel = 10;

  final int index;
  final Widget child;

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
