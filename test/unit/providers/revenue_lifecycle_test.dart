import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/utils/history_utils.dart';

class MockRevenueRepository extends Mock implements RevenueRepository {}

class FakeRevenueModel extends Fake implements RevenueModel {}

/// The revenue side answers to the same lifecycle as the expense side :
/// see recurring_lifecycle_test.dart. Closing a rule says when it stopped, not what it last paid : a rule
/// deleted today ran until today, and one whose day never came round never
/// ran at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(FakeRevenueModel()));

  late MockRevenueRepository repo;
  late RevenueModel? closed;
  late List<int> deleted;

  final today = dayOnly(DateTime.now());

  RevenueModel subscription({
    required DateTime startDate,
    String frequency = 'Mensuel',
  }) {
    final revenue = RevenueModel.create(
      name: 'Chomage',
      amount: 20,
      startDate: startDate,
      frequency: frequency,
      accountId: 1,
    );
    revenue.id = 7;
    return revenue;
  }

  setUp(() {
    repo = MockRevenueRepository();
    closed = null;
    deleted = [];

    when(() => repo.getActive()).thenReturn([]);
    when(() => repo.getClosed()).thenReturn([]);
    when(() => repo.update(any())).thenAnswer((invocation) {
      closed = invocation.positionalArguments.first as RevenueModel;
      return 7;
    });
    when(() => repo.delete(any())).thenAnswer((invocation) {
      deleted.add(invocation.positionalArguments.first as int);
      return true;
    });
    when(() => repo.add(any())).thenReturn(8);
    when(() => repo.getChain(any())).thenReturn([]);
  });

  Future<RevenueNotifier> notifierWith(RevenueModel revenue) async {
    when(() => repo.get(7)).thenReturn(revenue);
    when(() => repo.getActive()).thenReturn([revenue]);
    final container = ProviderContainer(
      overrides: [revenueRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(revenueProvider.future);
    return container.read(revenueProvider.notifier);
  }

  group('deleting a rule that has already run', () {
    test('closes it on the day it was deleted', () async {
      final revenue = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );

      await (await notifierWith(revenue)).deleteRevenue(7);

      expect(dayOnly(closed!.endDate!), today);
      expect(deleted, isEmpty);
    });

    test('keeps it on the month it was deleted in', () async {
      final revenue = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );

      await (await notifierWith(revenue)).deleteRevenue(7);

      expect(
        occursInMonth(
          closed!.startDate,
          closed!.endDate,
          closed!.frequencyEnum,
          DateTime(today.year, today.month),
        ),
        isTrue,
      );
    });

    test('drops it on the month after', () async {
      final revenue = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );

      await (await notifierWith(revenue)).deleteRevenue(7);

      expect(
        occursInMonth(
          closed!.startDate,
          closed!.endDate,
          closed!.frequencyEnum,
          DateTime(today.year, today.month + 1),
        ),
        isFalse,
      );
    });
  });

  group('deleting a rule that never ran', () {
    test('a rule starting next month is removed for good', () async {
      final revenue = subscription(
        startDate: today.add(const Duration(days: 10)),
      );

      await (await notifierWith(revenue)).deleteRevenue(7);

      expect(deleted, [7]);
      expect(closed, isNull);
    });

    test('a rule whose day has not come round yet is removed too', () async {
      final tomorrow = today.add(const Duration(days: 1));
      final revenue = subscription(startDate: tomorrow);

      await (await notifierWith(revenue)).deleteRevenue(7);

      expect(deleted, [7]);
    });
  });

  group('a one-off', () {
    test('is removed for good, whenever it was', () async {
      final revenue = subscription(
        startDate: today.subtract(const Duration(days: 3)),
        frequency: 'Ponctuel',
      );

      await (await notifierWith(revenue)).deleteRevenue(7);

      expect(deleted, [7]);
    });
  });

  group('editing a rule that has already run', () {
    test('closes the old row on the day of the edit', () async {
      final revenue = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );
      final notifier = await notifierWith(revenue);

      await notifier.updateRevenue(revenue.copyWith(amount: 35));

      expect(dayOnly(closed!.endDate!), today);
      expect(deleted, isEmpty);
    });
  });

  group('editing a rule that never ran', () {
    test('replaces it outright rather than leaving a dead row', () async {
      final revenue = subscription(
        startDate: today.add(const Duration(days: 10)),
      );
      final notifier = await notifierWith(revenue);

      await notifier.updateRevenue(revenue.copyWith(amount: 35));

      expect(deleted, [7]);
      expect(closed, isNull);
    });
  });

  group('refiling a rule under another category', () {
    late List<RevenueModel> chain;
    late List<RevenueModel> written;

    setUp(() {
      final august = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      )..endDate = DateTime(today.year, today.month - 1, 1);
      final live = subscription(startDate: DateTime(today.year, today.month, 1))
        ..id = 9;
      chain = [august, live];
      written = [];

      when(() => repo.getChain(any())).thenReturn(chain);
      when(() => repo.update(any())).thenAnswer((invocation) {
        written.add(invocation.positionalArguments.first as RevenueModel);
        return 7;
      });
    });

    test('reaches every month the rule ever ran, and splits nothing', () async {
      final revenue = chain.first;
      final notifier = await notifierWith(revenue);

      await notifier.updateRevenue(
        revenue.copyWith(categorySlug: 'finance.frais_bancaires'),
      );

      expect(written.length, 2);
      expect(
        written.every((e) => e.categorySlug == 'finance.frais_bancaires'),
        isTrue,
      );
      verifyNever(() => repo.add(any()));
    });

    test('reaches the whole chain even when the amount changes with '
        'it', () async {
      final revenue = chain.first;
      final notifier = await notifierWith(revenue);

      await notifier.updateRevenue(
        revenue.copyWith(amount: 35, categorySlug: 'finance.frais_bancaires'),
      );

      expect(
        chain.every((e) => e.categorySlug == 'finance.frais_bancaires'),
        isTrue,
      );
      verify(() => repo.add(any())).called(1);
    });

    test('leaves the past months alone when nothing else is touched', () async {
      final revenue = chain.first;
      final notifier = await notifierWith(revenue);

      await notifier.updateRevenue(revenue.copyWith(name: 'Chomage Pro'));

      expect(written.any((e) => e.name == 'Chomage Pro'), isFalse);
    });
  });

  group('changing the agreement itself', () {
    test('a new amount opens a rule taking over', () async {
      final revenue = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );
      final notifier = await notifierWith(revenue);

      await notifier.updateRevenue(revenue.copyWith(amount: 35));

      verify(() => repo.add(any())).called(1);
    });

    test(
      'a new name opens one too : the past months kept the old one',
      () async {
        final revenue = subscription(
          startDate: DateTime(today.year, today.month - 2, 1),
        );
        final notifier = await notifierWith(revenue);

        await notifier.updateRevenue(revenue.copyWith(name: 'Chomage Pro'));

        verify(() => repo.add(any())).called(1);
        expect(dayOnly(closed!.endDate!), today);
      },
    );

    test('a new beneficiary opens one as well', () async {
      final revenue = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );
      final notifier = await notifierWith(revenue);

      await notifier.updateRevenue(revenue.copyWith(beneficiaryId: 4));

      verify(() => repo.add(any())).called(1);
    });

    test('a new account opens one too, so past months keep theirs', () async {
      final revenue = subscription(
        startDate: DateTime(today.year, today.month - 2, 1),
      );
      final notifier = await notifierWith(revenue);

      await notifier.updateRevenue(revenue.copyWith(accountId: 3));

      verify(() => repo.add(any())).called(1);
    });
  });

  group('whatever the edit or the delete', () {
    test('never writes an end that precedes the start', () async {
      for (final offset in [-60, -1, 0, 1, 10, 40]) {
        closed = null;
        final revenue = subscription(
          startDate: today.add(Duration(days: offset)),
        );
        final notifier = await notifierWith(revenue);

        await notifier.deleteRevenue(7);
        if (closed != null) {
          expect(
            closed!.endDate!.isBefore(dayOnly(closed!.startDate)),
            isFalse,
            reason: 'delete at offset $offset',
          );
        }
      }
    });
  });
}
