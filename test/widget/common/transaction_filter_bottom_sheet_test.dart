import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/models/transaction_filter_data.dart';
import 'package:mybudget/ui/common/widgets/transaction_filter_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  CategoryDisplay category(String slug, String label) => CategoryDisplay(
    slug: slug,
    label: label,
    icon: 'paid',
    color: 0xFF4CAF50,
    groupKey: slug,
    groupLabel: label,
    type: TransactionType.expense,
  );

  TransactionFilterData? applied;

  Future<void> pump(
    WidgetTester tester, {
    TransactionFilterData initialFilterData = const TransactionFilterData(),
    List<CategoryDisplay> categories = const [],
    List<AccountModel> accounts = const [],
    List<Beneficiary> beneficiaries = const [],
    double highestAmount = 1000,
    int Function(TransactionFilterData)? resultCount,
  }) async {
    applied = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    unawaited(
      Navigator.push(
        tester.element(find.byType(SizedBox)),
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: TransactionFilterBottomSheet(
              initialFilterData: initialFilterData,
              categories: categories,
              accounts: accounts,
              beneficiaries: beneficiaries,
              highestAmount: highestAmount,
              resultCount: resultCount ?? (_) => 0,
              onApply: (filter) => applied = filter,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers one chip per beneficiary and applies the selection', (
    tester,
  ) async {
    await pump(tester, beneficiaries: [beneficiary(7, 'Camille')]);

    expect(find.text('BÉNÉFICIAIRE'), findsOneWidget);
    await tester.tap(find.text('Camille'));
    await tester.pump();
    await tester.tap(find.textContaining('Voir '));
    await tester.pump();

    expect(applied?.beneficiaryIds, [7]);
  });

  testWidgets('hides a section when it has nothing to offer', (tester) async {
    await pump(tester);

    expect(find.text('BÉNÉFICIAIRE'), findsNothing);
    expect(find.text('COMPTE'), findsNothing);
    expect(find.text('CATÉGORIES'), findsNothing);
    expect(find.text('TYPE'), findsOneWidget);
  });

  testWidgets('shows how many rows the pending filter would keep', (
    tester,
  ) async {
    await pump(
      tester,
      accounts: [account(1, 'Courant')],
      resultCount: (filter) => filter.accountIds.isEmpty ? 12 : 3,
    );

    expect(find.text('Voir 12 résultats'), findsOneWidget);

    await tester.tap(find.text('Courant'));
    await tester.pump();

    expect(find.text('Voir 3 résultats'), findsOneWidget);
  });

  testWidgets('reset drops the pending selections', (tester) async {
    await pump(
      tester,
      categories: [category('logement', 'Logement')],
      initialFilterData: const TransactionFilterData(
        groupKeys: ['logement'],
        types: [Frequency.monthly],
      ),
    );

    await tester.tap(find.text('Réinitialiser'));
    await tester.pump();
    await tester.tap(find.textContaining('Voir '));
    await tester.pump();

    expect(applied?.groupKeys, isEmpty);
    expect(applied?.types, isEmpty);
  });

  testWidgets('caps the amount slider at the highest amount in scope', (
    tester,
  ) async {
    await pump(tester, highestAmount: 347.2);

    expect(find.text('350 €'), findsOneWidget);
    expect(find.text('0 € – 350 €'), findsOneWidget);
  });

  testWidgets('pulls a stale amount range back under the cap', (tester) async {
    await pump(
      tester,
      highestAmount: 200,
      initialFilterData: const TransactionFilterData(
        minAmount: 50,
        maxAmount: 9000,
      ),
    );

    await tester.tap(find.textContaining('Voir '));
    await tester.pump();

    expect(applied?.minAmount, 50);
    expect(applied?.maxAmount, isNull);
  });

  testWidgets('keeps the search query untouched', (tester) async {
    await pump(
      tester,
      initialFilterData: const TransactionFilterData(searchQuery: 'loyer'),
    );

    await tester.tap(find.textContaining('Voir '));
    await tester.pump();

    expect(applied?.searchQuery, 'loyer');
  });
}
