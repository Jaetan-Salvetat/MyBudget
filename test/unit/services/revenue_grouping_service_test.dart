import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/revenue_grouping_service.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/revenue_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategoryDisplayResolver categoryResolver;

  setUpAll(() async {
    final taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
    categoryResolver = CategoryDisplayResolver(
      taxonomy: taxonomy,
      overrides: const {},
    );
  });

  RevenueModel revenue({
    String name = 'Revenu',
    double amount = 100,
    Frequency frequency = Frequency.monthly,
    int accountId = 1,
    int? beneficiaryId,
    String? categorySlug,
  }) {
    return RevenueModel.create(
      name: name,
      amount: amount,
      startDate: DateTime(2026, 8, 5),
      accountId: accountId,
      frequency: frequency.label,
      beneficiaryId: beneficiaryId,
      categorySlug: categorySlug,
    );
  }

  AccountModel account(int id, String name) {
    final model = AccountModel.create(name: name, bank: 'Banque');
    model.id = id;
    return model;
  }

  Beneficiary beneficiary(int id, String name) {
    final model = BeneficiaryModel.create(name: name);
    model.id = id;
    return Beneficiary.fromModel(model);
  }

  group('frequency axis', () {
    test('keeps the calendar order, not the amount order', () {
      final groups = RevenueGroupingService.group([
        revenue(name: 'Vente', amount: 900, frequency: Frequency.oneTime),
        revenue(name: 'Salaire', amount: 200),
        revenue(name: 'Prime', amount: 500, frequency: Frequency.annual),
      ], const FrequencyRevenueGrouper());

      expect(groups.map((g) => g.label), ['Mensuels', 'Annuels', 'Ponctuels']);
    });

    test('sums the amounts of a group', () {
      final groups = RevenueGroupingService.group([
        revenue(amount: 200),
        revenue(amount: 150),
      ], const FrequencyRevenueGrouper());

      expect(groups.single.total, 350);
      expect(groups.single.items, hasLength(2));
    });
  });

  group('category axis', () {
    test('groups on the taxonomy group, not on the leaf', () {
      final groups = RevenueGroupingService.group([
        revenue(amount: 2000, categorySlug: 'salaire.salaire_net'),
        revenue(amount: 300, categorySlug: 'salaire.prime'),
        revenue(amount: 100, categorySlug: 'aide_allocation.bourse'),
      ], CategoryRevenueGrouper(categoryResolver));

      expect(groups.map((g) => g.label), ['Salaire', 'Aides & Allocations']);
      expect(groups.first.total, 2300);
    });

    test('sorts groups by descending total', () {
      final groups = RevenueGroupingService.group([
        revenue(amount: 100, categorySlug: 'salaire.salaire_net'),
        revenue(amount: 800, categorySlug: 'exceptionnel.loyer_percu'),
      ], CategoryRevenueGrouper(categoryResolver));

      expect(groups.map((g) => g.label), ['Exceptionnel', 'Salaire']);
    });

    test('buckets a missing or unknown slug last', () {
      final groups = RevenueGroupingService.group([
        revenue(amount: 5000),
        revenue(amount: 10, categorySlug: 'slug_disparu'),
        revenue(amount: 20, categorySlug: 'salaire.salaire_net'),
      ], CategoryRevenueGrouper(categoryResolver));

      expect(groups.last.label, 'Non catégorisé');
      expect(groups.last.total, 5010);
    });
  });

  group('beneficiary axis', () {
    test('labels each group with the beneficiary name', () {
      final groups = RevenueGroupingService.group(
        [
          revenue(amount: 2000, beneficiaryId: 1),
          revenue(amount: 1500, beneficiaryId: 2),
          revenue(amount: 200, beneficiaryId: 1),
        ],
        BeneficiaryRevenueGrouper([
          beneficiary(1, 'Alex'),
          beneficiary(2, 'Camille'),
        ]),
      );

      expect(groups.map((g) => g.label), ['Alex', 'Camille']);
      expect(groups.first.total, 2200);
    });

    test('buckets an unassigned or deleted beneficiary last', () {
      final groups = RevenueGroupingService.group([
        revenue(amount: 9000),
        revenue(amount: 42, beneficiaryId: 404),
        revenue(amount: 10, beneficiaryId: 1),
      ], BeneficiaryRevenueGrouper([beneficiary(1, 'Alex')]));

      expect(groups.last.label, 'Sans bénéficiaire');
      expect(groups.last.total, 9042);
    });
  });

  group('account axis', () {
    test('labels each group with the account name', () {
      final groups = RevenueGroupingService.group([
        revenue(amount: 1000, accountId: 1),
        revenue(amount: 300, accountId: 2),
      ], AccountRevenueGrouper([account(1, 'Courant'), account(2, 'Épargne')]));

      expect(groups.map((g) => g.label), ['Courant', 'Épargne']);
    });

    test('buckets a deleted account last', () {
      final groups = RevenueGroupingService.group([
        revenue(amount: 5000, accountId: 404),
        revenue(amount: 10, accountId: 1),
      ], AccountRevenueGrouper([account(1, 'Courant')]));

      expect(groups.last.label, 'Compte inconnu');
    });
  });

  group('none axis', () {
    test('returns a single unlabelled group', () {
      final groups = RevenueGroupingService.group([
        revenue(amount: 100),
        revenue(amount: 50),
      ], const FlatRevenueGrouper());

      expect(groups, hasLength(1));
      expect(groups.single.label, isEmpty);
      expect(groups.single.total, 150);
    });
  });

  test('returns no group for an empty list', () {
    expect(
      RevenueGroupingService.group(const [], const FrequencyRevenueGrouper()),
      isEmpty,
    );
  });

  group('share', () {
    test('is the group weight in the whole set', () {
      final groups = RevenueGroupingService.group(
        [
          revenue(amount: 750, beneficiaryId: 1),
          revenue(amount: 250, beneficiaryId: 2),
        ],
        BeneficiaryRevenueGrouper([
          beneficiary(1, 'Alex'),
          beneficiary(2, 'Camille'),
        ]),
      );

      expect(groups.first.share, 0.75);
      expect(groups.last.share, 0.25);
    });

    test('is zero when every amount is zero', () {
      final groups = RevenueGroupingService.group([
        revenue(amount: 0),
      ], const FrequencyRevenueGrouper());

      expect(groups.single.share, 0);
    });
  });

  group('grouper for an axis', () {
    RevenueGrouper grouperFor(
      RevenueGroupBy axis, {
      CategoryDisplayResolver? resolver,
    }) {
      return RevenueGroupingService.grouperFor(
        axis,
        categoryResolver: resolver ?? categoryResolver,
        beneficiaries: const [],
        accounts: const [],
      );
    }

    test('maps every axis to its grouper', () {
      expect(
        grouperFor(RevenueGroupBy.frequency),
        isA<FrequencyRevenueGrouper>(),
      );
      expect(
        grouperFor(RevenueGroupBy.category),
        isA<CategoryRevenueGrouper>(),
      );
      expect(
        grouperFor(RevenueGroupBy.beneficiary),
        isA<BeneficiaryRevenueGrouper>(),
      );
      expect(grouperFor(RevenueGroupBy.account), isA<AccountRevenueGrouper>());
      expect(grouperFor(RevenueGroupBy.none), isA<FlatRevenueGrouper>());
    });

    test('falls back to a flat list while the taxonomy is loading', () {
      expect(
        RevenueGroupingService.grouperFor(
          RevenueGroupBy.category,
          categoryResolver: null,
          beneficiaries: const [],
          accounts: const [],
        ),
        isA<FlatRevenueGrouper>(),
      );
    });
  });
}
