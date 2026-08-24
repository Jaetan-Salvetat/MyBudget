import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';

/// The transactions just recorded, one line each under the input : the field
/// is already back to empty, these say what landed and hold the way back.
class QuickAddSubmissionTicker extends ConsumerWidget {
  const QuickAddSubmissionTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissions = ref.watch(quickAddRecentSubmissionsProvider);
    final motion = context.frostedTokens.motion.snappy;

    return AnimatedSize(
      duration: motion.duration,
      curve: motion.curve,
      alignment: Alignment.topCenter,
      child: submissions.isEmpty
          ? const SizedBox(width: double.infinity)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final submission in submissions)
                  Padding(
                    key: ObjectKey(submission),
                    padding: const EdgeInsets.only(top: FrostedSpacing.sp2),
                    child: _SubmissionLine(
                      submission: submission,
                      onUndo: () => _undo(ref, submission),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _undo(WidgetRef ref, QuickAddSubmission submission) async {
    ref
        .read(quickAddRecentSubmissionsProvider.notifier)
        .dismiss(submission);
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(quickAddProvider.notifier).undo(submission);
  }
}

class _SubmissionLine extends StatelessWidget {
  final QuickAddSubmission submission;
  final VoidCallback onUndo;

  const _SubmissionLine({required this.submission, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = context.financeColors;
    final isIncome = submission.type == TransactionType.income;
    final accent = isIncome ? finance.income : finance.expense;

    return _FadeIn(
      child: Row(
        children: [
          Icon(Symbols.check_circle_rounded, size: 16, color: accent),
          const SizedBox(width: FrostedSpacing.sp2),
          Expanded(
            child: Text(
              '${submission.name} ${_amountLabel(isIncome)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.mono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          InkWell(
            onTap: onUndo,
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
          ),
        ],
      ),
    );
  }

  String _amountLabel(bool isIncome) {
    final formatted = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    ).format(submission.amount);
    return isIncome ? '+ $formatted' : '− $formatted';
  }
}

class _FadeIn extends StatefulWidget {
  final Widget child;

  const _FadeIn({required this.child});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 240);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: context.frostedTokens.motion.snappy.curve,
      ),
      child: widget.child,
    );
  }
}
