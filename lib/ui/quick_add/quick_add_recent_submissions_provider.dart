import 'dart:async';

import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_recent_submissions_provider.g.dart';

@riverpod
class QuickAddRecentSubmissions extends _$QuickAddRecentSubmissions {
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
