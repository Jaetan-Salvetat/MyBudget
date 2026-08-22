import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/category_override_repository.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classification.dart';
import 'package:mybudget/core/services/quick_add/quick_add_classifier_service.dart';
import 'package:mybudget/core/services/category_memory_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_bar.dart';

class MockClassifierService extends Mock implements QuickAddClassifierService {}

class MockCategoryMemoryService extends Mock implements CategoryMemoryService {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class FakeAccountNotifier extends AccountNotifier {
  FakeAccountNotifier(this._accounts);

  final List<AccountModel> _accounts;

  @override
  Future<List<AccountModel>> build() async => _accounts;
}

AccountModel accountOf(int id, String name) {
  final account = AccountModel.create(name: name, bank: 'CM');
  account.id = id;
  return account;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClassifierService classifier;
  late MockCategoryMemoryService memory;
  late MockCategoryOverrideRepository overrides;
  late CategoryTaxonomyService taxonomy;

  setUpAll(() async {
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  setUp(() {
    classifier = MockClassifierService();
    memory = MockCategoryMemoryService();
    overrides = MockCategoryOverrideRepository();

    when(() => memory.recall(any())).thenReturn(null);
    when(() => overrides.getAll()).thenReturn({});
    when(() => classifier.classify(any())).thenAnswer(
      (_) async => QuickAddClassification(
        type: TransactionType.expense,
        category: taxonomy.resolve('restauration.fast_food')!,
        frequency: Frequency.oneTime,
        amount: 12.0,
        name: 'Mc do',
        typeConfidence: 0.99,
        categoryConfidence: 0.9,
        recurrenceConfidence: 0.9,
        cleanedText: 'mc do',
      ),
    );
  });

  Future<void> pumpBar(WidgetTester tester, {bool focused = true}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProvider.overrideWith(
            () => FakeAccountNotifier([accountOf(1, 'Courant')]),
          ),
          categoryMemoryProvider.overrideWithValue(memory),
          categoryOverrideRepositoryProvider.overrideWithValue(overrides),
          quickAddClassifierProvider.overrideWith((ref) => classifier),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: QuickAddBar(
              focused: focused,
              onFocusChanged: (_) {},
              onNoAccount: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('offers no way out while there is nothing to leave', (
    tester,
  ) async {
    await pumpBar(tester, focused: false);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.close_rounded), findsNothing);
  });

  testWidgets('offers a way out as soon as the field is focused', (
    tester,
  ) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.close_rounded), findsOneWidget);
  });

  testWidgets('cancelling empties the field and the draft', (tester) async {
    await pumpBar(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mc do 12');
    await tester.pump(
      QuickAddNotifier.analysisDebounce + const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(QuickAddBar)),
    );
    expect(container.read(quickAddProvider).amount, 12.0);

    await tester.tap(find.byIcon(Symbols.close_rounded));
    await tester.pumpAndSettle();

    expect(container.read(quickAddProvider).isEmpty, isTrue);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
  });
}
