import 'dart:async';

import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_recent_submissions_provider.g.dart';

/// The transactions the quick-add just recorded, each shown long enough to be
/// undone then let go on its own : the rafale never waits on a snackbar.
@riverpod
class QuickAddRecentSubmissions extends _$QuickAddRecentSubmissions {
  /// Long enough to read the line and change one's mind, short enough that a
  /// rafale never stacks more than a couple of them.
  static const Duration retention = Duration(seconds: 5);

  final Map<QuickAddSubmission, Timer> _expiries = {};

  @override
  List<QuickAddSubmission> build() {
    ref.onDispose(_cancelExpiries);
    return const [];
  }

  void push(QuickAddSubmission submission) {
    state = [...state, submission];
    _expiries[submission] = Timer(retention, () => dismiss(submission));
  }

  /// Keyed on the instance, not the id : an expense and a revenue can share
  /// one, they live in different tables.
  void dismiss(QuickAddSubmission submission) {
    _expiries.remove(submission)?.cancel();
    state = state
        .where((candidate) => !identical(candidate, submission))
        .toList();
  }

  void _cancelExpiries() {
    for (final timer in _expiries.values) {
      timer.cancel();
    }
    _expiries.clear();
  }
}
