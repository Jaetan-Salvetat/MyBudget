import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/values/category_display.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/provider/beneficiary_provider.dart';
import 'package:mybudget/data/provider/category_override_provider.dart';
import 'package:mybudget/data/provider/expenses_provider.dart';
import 'package:mybudget/data/service/category_display_resolver.dart';
import 'package:mybudget/ui/stats/stats_provider.dart';

import 'harness/e2e_harness.dart';

void main() {
  late E2EHarness app;

  final DateTime now = E2EHarness.defaultNow;

  setUp(() async {
    app = await E2EHarness.start(now: now);
  });

  tearDown(() => app.dispose());

  CategoryOverrideNotifier overrides() =>
      app.container.read(categoryOverrideProvider.notifier);

  BeneficiaryNotifier beneficiaries() =>
      app.container.read(beneficiaryProvider.notifier);

  Future<CategoryDisplayResolver> resolver() =>
      app.container.read(categoryDisplayResolverProvider.future);

  Future<int> addRent({int? beneficiaryId}) {
    return app.container
        .read(expenseProvider.notifier)
        .addExpense(
          ExpenseModel.create(
            name: 'Loyer',
            amount: 900,
            categorySlug: 'logement.loyer',
            startDate: DateTime(2026, 6, 5),
            frequency: Frequency.monthly,
            accountId: 1,
            beneficiaryId: beneficiaryId,
          ),
        );
  }

  group('la personnalisation d\'une catégorie', () {
    test('remplace le libellé affiché', () async {
      await overrides().customize('logement.loyer', name: 'Toit');

      final CategoryDisplay? display = (await resolver()).resolve(
        'logement.loyer',
      );

      expect(display?.label, 'Toit');
    });

    test(
      'la couleur se personnalise sur le groupe, pas sur la feuille',
      () async {
        await overrides().customize('logement.loyer', color: 0xFF112233);

        final CategoryDisplay leaf = (await resolver()).resolve(
          'logement.loyer',
        )!;

        expect(leaf.color, isNot(0xFF112233));
      },
    );

    test('la couleur du groupe descend sur ses feuilles', () async {
      await overrides().customize('logement', color: 0xFF112233);

      final CategoryDisplayResolver display = await resolver();

      expect(display.resolveGroup('logement')?.color, 0xFF112233);
    });

    test('ne touche pas aux autres catégories', () async {
      await overrides().customize('logement.loyer', name: 'Toit');

      final CategoryDisplay? other = (await resolver()).resolve(
        'alimentation.courses',
      );

      expect(other?.label, isNot('Toit'));
    });

    test('est rangée dans le dépôt sous son slug', () async {
      await overrides().customize('logement.loyer', name: 'Toit');

      expect(app.categoryOverrides.getAll().keys, <String>['logement.loyer']);
    });

    test('remise à zéro, elle rend son libellé d\'origine', () async {
      final String original = (await resolver())
          .resolve('logement.loyer')!
          .label;
      await overrides().customize('logement.loyer', name: 'Toit');

      await overrides().reset('logement.loyer');

      expect((await resolver()).resolve('logement.loyer')?.label, original);
      expect(app.categoryOverrides.getAll(), isEmpty);
    });

    test('une personnalisation vide n\'est pas conservée', () async {
      await overrides().customize('logement.loyer');

      expect(app.categoryOverrides.getAll(), isEmpty);
    });

    test('se voit dans la répartition des stats', () async {
      app.container.listen(statsProvider, (_, _) {}, fireImmediately: true);
      await addRent();
      await overrides().customize('logement', name: 'Chez moi');
      await app.container.read(categoryDisplayResolverProvider.future);

      expect(app.container.read(statsProvider).slices.single.label, 'Chez moi');
    });
  });

  group('les bénéficiaires', () {
    test('un nouveau bénéficiaire apparaît dans la liste', () async {
      await beneficiaries().addBeneficiary('Agence');

      final List<BeneficiaryModel> all = await app.container.read(
        beneficiaryProvider.future,
      );

      expect(all.map((BeneficiaryModel b) => b.name), <String>['Agence']);
    });

    test('la liste est rangée par ordre alphabétique', () async {
      await beneficiaries().addBeneficiary('Zoé');
      await beneficiaries().addBeneficiary('Agence');

      final List<BeneficiaryModel> all = await app.container.read(
        beneficiaryProvider.future,
      );

      expect(all.map((BeneficiaryModel b) => b.name), <String>['Agence', 'Zoé']);
    });

    test('un nom vide est refusé', () async {
      final String? error = await beneficiaries().addBeneficiary('   ');

      expect(error, 'Le nom ne peut pas être vide');
      expect(app.beneficiaries.getAll(), isEmpty);
    });

    test('un doublon est refusé, quelle que soit la casse', () async {
      await beneficiaries().addBeneficiary('Agence');

      final String? error = await beneficiaries().addBeneficiary('AGENCE');

      expect(error, 'Ce bénéficiaire existe déjà');
      expect(app.beneficiaries.getAll(), hasLength(1));
    });

    test('le renommage prend effet', () async {
      final int? id = await beneficiaries().createBeneficiary('Agence');

      final String? error = await beneficiaries().renameBeneficiary(
        id!,
        'Agence Sud',
      );

      expect(error, isNull);
      expect(app.beneficiaries.get(id)!.name, 'Agence Sud');
    });

    test('renommer vers un nom déjà pris est refusé', () async {
      await beneficiaries().addBeneficiary('Agence');
      final int? id = await beneficiaries().createBeneficiary('Plombier');

      final String? error = await beneficiaries().renameBeneficiary(
        id!,
        'Agence',
      );

      expect(error, 'Ce bénéficiaire existe déjà');
      expect(app.beneficiaries.get(id)!.name, 'Plombier');
    });

    test('un bénéficiaire inutilisé se supprime', () async {
      final int? id = await beneficiaries().createBeneficiary('Agence');

      final String? error = await beneficiaries().deleteBeneficiary(id!);

      expect(error, isNull);
      expect(app.beneficiaries.getAll(), isEmpty);
    });

    test('un bénéficiaire utilisé refuse d\'être supprimé', () async {
      final int? id = await beneficiaries().createBeneficiary('Agence');
      await addRent(beneficiaryId: id);

      final String? error = await beneficiaries().deleteBeneficiary(id!);

      expect(error, 'Ce bénéficiaire est utilisé par 1 transaction');
      expect(app.beneficiaries.getAll(), hasLength(1));
    });

    test('le décompte des usages accorde le pluriel', () async {
      final int? id = await beneficiaries().createBeneficiary('Agence');
      await addRent(beneficiaryId: id);
      await addRent(beneficiaryId: id);

      expect(beneficiaries().countUsages(id!), 2);
      expect(
        await beneficiaries().deleteBeneficiary(id),
        'Ce bénéficiaire est utilisé par 2 transactions',
      );
    });

    test('reçoit une couleur dès sa création', () async {
      await beneficiaries().addBeneficiary('Agence');

      expect(app.beneficiaries.getAll().single.color, isNot(0));
    });
  });
}
