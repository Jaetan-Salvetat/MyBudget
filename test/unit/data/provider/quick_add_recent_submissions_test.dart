import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/data/model/quick_add_submission_model.dart';
import 'package:mybudget/data/provider/quick_add_recent_submissions_provider.dart';

QuickAddSubmission submissionOf(int id, {String name = 'café'}) {
  return QuickAddSubmission(
    id: id,
    type: TransactionType.expense,
    name: name,
    amount: 3.5,
  );
}

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(
      quickAddRecentSubmissionsProvider,
      (_, _) {},
      fireImmediately: true,
    );
    return container;
  }

  test('starts empty', () {
    final container = makeContainer();
    expect(container.read(quickAddRecentSubmissionsProvider), isEmpty);
  });

  test('keeps the submissions in the order they were pushed', () {
    fakeAsync((async) {
      final container = makeContainer();
      final notifier = container.read(
        quickAddRecentSubmissionsProvider.notifier,
      );

      final first = submissionOf(1, name: 'café');
      final second = submissionOf(2, name: 'pain');
      notifier.push(first);
      notifier.push(second);

      expect(container.read(quickAddRecentSubmissionsProvider), [
        first,
        second,
      ]);
    });
  });

  test('drops a submission once the retention has passed', () {
    fakeAsync((async) {
      final container = makeContainer();
      final notifier = container.read(
        quickAddRecentSubmissionsProvider.notifier,
      );

      notifier.push(submissionOf(1));
      async.elapse(QuickAddRecentSubmissions.retention);

      expect(container.read(quickAddRecentSubmissionsProvider), isEmpty);
    });
  });

  test('each submission lives its own retention', () {
    fakeAsync((async) {
      final container = makeContainer();
      final notifier = container.read(
        quickAddRecentSubmissionsProvider.notifier,
      );

      final first = submissionOf(1);
      notifier.push(first);
      async.elapse(const Duration(seconds: 3));
      final second = submissionOf(2);
      notifier.push(second);
      async.elapse(const Duration(seconds: 3));

      expect(container.read(quickAddRecentSubmissionsProvider), [second]);
    });
  });

  test('dismiss removes the submission and cancels its expiry', () {
    fakeAsync((async) {
      final container = makeContainer();
      final notifier = container.read(
        quickAddRecentSubmissionsProvider.notifier,
      );

      final submission = submissionOf(1);
      notifier.push(submission);
      notifier.dismiss(submission);

      expect(container.read(quickAddRecentSubmissionsProvider), isEmpty);
      async.elapse(QuickAddRecentSubmissions.retention);
      expect(container.read(quickAddRecentSubmissionsProvider), isEmpty);
    });
  });

  test('two submissions sharing an id stay distinct', () {
    fakeAsync((async) {
      final container = makeContainer();
      final notifier = container.read(
        quickAddRecentSubmissionsProvider.notifier,
      );

      final expense = submissionOf(1, name: 'café');
      final other = submissionOf(1, name: 'salaire');
      notifier.push(expense);
      notifier.push(other);
      notifier.dismiss(expense);

      expect(container.read(quickAddRecentSubmissionsProvider), [other]);
    });
  });
}
