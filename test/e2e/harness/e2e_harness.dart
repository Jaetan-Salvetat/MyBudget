import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/build_flavor.dart';
import 'package:mybudget/core/formatting/locales.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/data/model/receipt_scan_result_model.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/provider/quick_add_engine_provider.dart';
import 'package:mybudget/data/provider/receipt_reader_provider.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:mybudget/data/service/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/ui/capture/quick_add_provider.dart';
import 'package:mybudget/ui/home/home_screen.dart';
import 'package:mybudget/ui/shared/home_navigation_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_quick_add_engine.dart';
import 'fake_receipt_reader.dart';
import 'in_memory_repositories.dart';

const String pathProviderChannel = 'plugins.flutter.io/path_provider';

class E2EHarness {
  E2EHarness._({
    required this.now,
    required this.taxonomy,
    required this.tempDir,
  }) : engine = FakeQuickAddEngine(taxonomy: taxonomy, now: now);

  final DateTime now;
  final CategoryTaxonomyService taxonomy;
  final Directory tempDir;
  final FakeQuickAddEngine engine;
  final FakeReceiptScanner scanner = FakeReceiptScanner();

  ReceiptScanResultModel _receipt = _emptyReceipt;

  final InMemoryAccountRepository accounts = InMemoryAccountRepository();
  final InMemoryBeneficiaryRepository beneficiaries =
      InMemoryBeneficiaryRepository();
  final InMemoryExpenseRepository expenses = InMemoryExpenseRepository();
  final InMemoryRevenueRepository revenues = InMemoryRevenueRepository();
  final InMemoryTransferRepository transfers = InMemoryTransferRepository();
  final InMemoryLoanRepository loans = InMemoryLoanRepository();
  final InMemoryLoanEventRepository loanEvents = InMemoryLoanEventRepository();
  final InMemoryCategoryOverrideRepository categoryOverrides =
      InMemoryCategoryOverrideRepository();
  final InMemoryCategoryMemoryRepository categoryMemory =
      InMemoryCategoryMemoryRepository();
  final InMemoryTransactionEventRepository transactionEvents =
      InMemoryTransactionEventRepository();
  final InMemoryLegacyCategoryRepository legacyCategories =
      InMemoryLegacyCategoryRepository();

  late final ProviderContainer container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => now),
      dataWipeFeedbackDelayProvider.overrideWithValue(Duration.zero),
      quickAddAnalysisDebounceProvider.overrideWithValue(Duration.zero),
      buildFlavorProvider.overrideWithValue(BuildFlavor.prod),
      appVersionProvider.overrideWithValue('1.0.0'),
      appBuildNumberProvider.overrideWithValue('1'),
      categoryTaxonomyProvider.overrideWith((Ref ref) async => taxonomy),
      quickAddEngineProvider.overrideWith((Ref ref) async => engine),
      cloudReceiptReaderProvider.overrideWith((Ref ref) async => null),
      nanoReceiptReaderProvider.overrideWith((Ref ref) => null),
      localReceiptScannerProvider.overrideWith((Ref ref) async => scanner),
      receiptScanComposerProvider.overrideWith(
        (Ref ref) async => FakeReceiptScanComposer(_receipt),
      ),
      accountRepositoryProvider.overrideWithValue(accounts),
      beneficiaryRepositoryProvider.overrideWithValue(beneficiaries),
      expenseRepositoryProvider.overrideWithValue(expenses),
      revenueRepositoryProvider.overrideWithValue(revenues),
      transferRepositoryProvider.overrideWithValue(transfers),
      loanRepositoryProvider.overrideWithValue(loans),
      loanEventRepositoryProvider.overrideWithValue(loanEvents),
      categoryOverrideRepositoryProvider.overrideWithValue(categoryOverrides),
      categoryMemoryRepositoryProvider.overrideWithValue(categoryMemory),
      transactionEventRepositoryProvider.overrideWithValue(transactionEvents),
      legacyCategoryRepositoryProvider.overrideWithValue(legacyCategories),
    ],
  );

  static CategoryTaxonomyService? _taxonomyCache;

  static Future<E2EHarness> start({DateTime? now}) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await initializeDateFormatting(DisplayLocale.tag, null);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();

    final CategoryTaxonomyService taxonomy = _taxonomyCache ??=
        await _loadTaxonomy();

    final Directory tempDir = Directory.systemTemp.createTempSync('mybudget');
    _installPathProvider(tempDir);

    final E2EHarness harness = E2EHarness._(
      now: now ?? defaultNow,
      taxonomy: taxonomy,
      tempDir: tempDir,
    );
    await harness.container.read(categoryTaxonomyProvider.future);
    return harness;
  }

  static final DateTime defaultNow = DateTime(2026, 6, 15, 10, 30);

  void dispose() {
    container.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(pathProviderChannel),
          null,
        );
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> goToTab(WidgetTester tester, HomeTab tab) async {
    await tester.tap(find.text(_tabLabels[tab.index]));
    await tester.pumpAndSettle();
  }

  static const List<String> _tabLabels = <String>[
    'Accueil',
    'Transactions',
    'Stats',
    'Comptes',
  ];

  void scriptReceipt(ReceiptScanResultModel receipt) {
    _receipt = receipt;
    container.invalidate(receiptScanComposerProvider);
  }

  static Future<CategoryTaxonomyService> _loadTaxonomy() async {
    final CategoryTaxonomyService taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
    return taxonomy;
  }

  static void _installPathProvider(Directory dir) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(pathProviderChannel), (
          MethodCall call,
        ) async {
          return dir.path;
        });
  }
}

final ReceiptScanResultModel _emptyReceipt = ReceiptScanResultModel(
  date: DateTime(2026, 6, 15),
  items: const [],
);
