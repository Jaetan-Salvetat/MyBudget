import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/models/journal_bucket.dart';
import 'package:mybudget/ui/capture/models/journal_entry.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;

  final DateTime monday = E2EHarness.defaultNow;

  setUp(() async {
    app = await E2EHarness.start(now: monday);
  });

  tearDown(() => app.dispose());

  Future<int> addExpense({
    required String name,
    required double amount,
    required DateTime startDate,
    Frequency frequency = Frequency.oneTime,
    String categorySlug = 'alimentation.courses',
  }) {
    return app.container
        .read(expenseProvider.notifier)
        .addExpense(
          ExpenseModel.create(
            name: name,
            amount: amount,
            categorySlug: categorySlug,
            startDate: startDate,
            frequency: frequency,
            accountId: 1,
          ),
        );
  }

  Future<int> addRevenue({
    required String name,
    required double amount,
    required DateTime startDate,
    Frequency frequency = Frequency.oneTime,
  }) {
    return app.container
        .read(revenueProvider.notifier)
        .addRevenue(
          RevenueModel.create(
            name: name,
            amount: amount,
            startDate: startDate,
            frequency: frequency,
            accountId: 1,
            categorySlug: 'salaire.salaire_net',
          ),
        );
  }

  List<JournalBucket> buckets() => app.container.read(journalBucketsProvider);

  JournalBucket bucketOf(JournalBucketKind kind) =>
      buckets().firstWhere((JournalBucket b) => b.kind == kind);

  List<String> namesIn(JournalBucketKind kind) =>
      bucketOf(kind).entries.map((JournalEntry e) => e.name).toList();

  group('le rangement par tranche', () {
    test('sépare aujourd\'hui, hier, la semaine et le mois', () async {
      await addExpense(name: 'Café', amount: 3, startDate: monday);
      await addExpense(
        name: 'Essence',
        amount: 60,
        startDate: DateTime(2026, 6, 14),
      );
      await addExpense(
        name: 'Cinéma',
        amount: 12,
        startDate: DateTime(2026, 6, 10),
      );
      await addExpense(
        name: 'Musée',
        amount: 8,
        startDate: DateTime(2026, 5, 20),
      );

      expect(namesIn(JournalBucketKind.today), <String>['Café']);
      expect(namesIn(JournalBucketKind.yesterday), <String>['Essence']);
      expect(namesIn(JournalBucketKind.lastWeek), <String>['Cinéma']);
      expect(namesIn(JournalBucketKind.month), <String>['Musée']);
    });

    test('n\'affiche rien de postérieur à aujourd\'hui', () async {
      await addExpense(
        name: 'Réservation',
        amount: 200,
        startDate: DateTime(2026, 6, 20),
      );

      expect(buckets(), isEmpty);
    });

    test('range les tranches de la plus récente à la plus ancienne', () async {
      await addExpense(name: 'Café', amount: 3, startDate: monday);
      await addExpense(
        name: 'Musée',
        amount: 8,
        startDate: DateTime(2026, 5, 20),
      );

      expect(buckets().map((JournalBucket b) => b.kind), <JournalBucketKind>[
        JournalBucketKind.today,
        JournalBucketKind.month,
      ]);
    });
  });

  group('la projection des récurrences', () {
    test('une mensuelle réapparaît chaque mois depuis son début', () async {
      await addExpense(
        name: 'Loyer',
        amount: 900,
        startDate: DateTime(2026, 4, 5),
        frequency: Frequency.monthly,
      );

      final List<DateTime> occurrences = <DateTime>[
        for (final JournalBucket bucket in buckets())
          for (final JournalEntry entry in bucket.entries) entry.at,
      ];

      expect(
        occurrences.map((DateTime d) => DateTime(d.year, d.month, d.day)),
        containsAll(<DateTime>[
          DateTime(2026, 4, 5),
          DateTime(2026, 5, 5),
          DateTime(2026, 6, 5),
        ]),
      );
    });

    test('une mensuelle clôturée cesse d\'apparaître après sa fin', () async {
      final int id = await addExpense(
        name: 'Sport',
        amount: 40,
        startDate: DateTime(2026, 4, 5),
        frequency: Frequency.monthly,
      );
      app.expenses.update(
        app.expenses.table.get(id)!.copyWith(endDate: DateTime(2026, 5, 10)),
      );
      app.container.invalidate(expenseProvider);
      await app.container.read(expenseProvider.future);

      final List<DateTime> occurrences = <DateTime>[
        for (final JournalBucket bucket in buckets())
          for (final JournalEntry entry in bucket.entries)
            DateTime(entry.at.year, entry.at.month, entry.at.day),
      ];

      expect(occurrences, contains(DateTime(2026, 5, 5)));
      expect(occurrences, isNot(contains(DateTime(2026, 6, 5))));
    });

    test('une annuelle ne tombe qu\'une fois dans l\'année', () async {
      await addExpense(
        name: 'Assurance',
        amount: 300,
        startDate: DateTime(2026, 4, 20),
        frequency: Frequency.annual,
      );

      final int count = buckets().fold<int>(
        0,
        (int sum, JournalBucket b) =>
            sum +
            b.entries.where((JournalEntry e) => e.name == 'Assurance').length,
      );

      expect(count, 1);
    });

    test('une ponctuelle ne tombe qu\'une fois', () async {
      await addExpense(
        name: 'Cadeau',
        amount: 45,
        startDate: DateTime(2026, 4, 20),
      );

      final int count = buckets().fold<int>(
        0,
        (int sum, JournalBucket b) =>
            sum +
            b.entries.where((JournalEntry e) => e.name == 'Cadeau').length,
      );

      expect(count, 1);
    });
  });

  group('la dépense du jour', () {
    test('compte les dépenses et retranche les revenus', () async {
      await addExpense(name: 'Courses', amount: 50, startDate: monday);
      await addRevenue(name: 'Remboursement', amount: 20, startDate: monday);

      expect(bucketOf(JournalBucketKind.today).spent, 30);
    });

    test('todayJournal ne rend que la tranche du jour', () async {
      await addExpense(name: 'Courses', amount: 50, startDate: monday);
      await addExpense(
        name: 'Essence',
        amount: 60,
        startDate: DateTime(2026, 6, 14),
      );

      final List<JournalEntry> today = app.container.read(todayJournalProvider);

      expect(today.map((JournalEntry e) => e.name), <String>['Courses']);
    });

    test('marque la provenance de chaque ligne', () async {
      await addExpense(name: 'Courses', amount: 50, startDate: monday);
      await addRevenue(name: 'Prime', amount: 200, startDate: monday);

      final List<JournalEntry> today = app.container.read(todayJournalProvider);

      expect(
        today.map((JournalEntry e) => e.source).toSet(),
        <JournalEntrySource>{
          JournalEntrySource.expense,
          JournalEntrySource.revenue,
        },
      );
    });
  });

  group('le reste du mois', () {
    test('vaut les revenus du mois moins les dépenses du mois', () async {
      await addRevenue(
        name: 'Salaire',
        amount: 2400,
        startDate: DateTime(2026, 1, 5),
        frequency: Frequency.monthly,
      );
      await addExpense(
        name: 'Loyer',
        amount: 900,
        startDate: DateTime(2026, 1, 5),
        frequency: Frequency.monthly,
      );

      expect(app.container.read(remainingThisMonthProvider), 1500);
    });

    test('ignore une dépense d\'un autre mois', () async {
      await addRevenue(
        name: 'Salaire',
        amount: 2400,
        startDate: DateTime(2026, 1, 5),
        frequency: Frequency.monthly,
      );
      await addExpense(
        name: 'Musée',
        amount: 8,
        startDate: DateTime(2026, 5, 20),
      );

      expect(app.container.read(remainingThisMonthProvider), 2400);
    });
  });
}
