import 'dart:async';
import 'dart:io' show FileSystemException;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:mybudget/ui/scan/scan_screen.dart';
import 'package:mybudget/ui/scan/widgets/scan_commit_bar.dart';
import 'package:mybudget/ui/scan/widgets/scan_item_list.dart';
import 'package:mybudget/ui/scan/widgets/scan_reading_thread.dart';
import 'package:mybudget/ui/scan/widgets/scan_receipt_header.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

import '../../helpers/scan_review_factory.dart';

class _StubScan extends ScanNotifier {
  _StubScan(this._state);

  final AsyncValue<ReceiptScanResultModel?> _state;

  @override
  AsyncValue<ReceiptScanResultModel?> build() => _state;

  @override
  Future<void> scanReceipt(Uint8List imageBytes) async {}
}

class _StubAccounts extends AccountNotifier {
  _StubAccounts(this._accounts);

  final List<AccountModel> _accounts;

  @override
  List<AccountModel> build() => _accounts;
}

late CategoryTaxonomyService taxonomy;

Future<void> pumpScreen(
  WidgetTester tester,
  AsyncValue<ReceiptScanResultModel?> state, {
  List<AccountModel> accounts = const [],
  Future<Uint8List>? image,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        scanProvider.overrideWith(() => _StubScan(state)),
        accountProvider.overrideWith(() => _StubAccounts(accounts)),
        categoryDisplayResolverProvider.overrideWith(
          (ref) async =>
              CategoryDisplayResolver(taxonomy: taxonomy, overrides: const {}),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: ScanScreen(image: image ?? Future.value(Uint8List(0))),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
    taxonomy = CategoryTaxonomyService();
    await taxonomy.load();
  });

  testWidgets('pendant la lecture, l\'écran ne montre qu\'un fil', (
    tester,
  ) async {
    await pumpScreen(tester, const AsyncLoading());

    expect(find.byType(ScanReadingThread), findsOneWidget);
    expect(
      find.text(ScanReceiptHeader.readingLabel.toUpperCase()),
      findsOneWidget,
    );
    expect(find.byType(ScanItemList), findsNothing);
    expect(find.byType(ScanCommitBar), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('le ticket lu ouvre la revue et sa barre de validation', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      AsyncData(
        scanResult(
          items: [
            scannedItem(name: 'Pain complet'),
            scannedItem(name: 'Piles LR6', slug: null, confidence: 0),
          ],
        ),
      ),
      accounts: [
        AccountModel.create(name: 'Compte courant', bank: 'B')..id = 1,
      ],
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(ScanItemList), findsOneWidget);
    expect(find.byType(ScanReadingThread), findsNothing);
    expect(find.text('Pain complet'), findsOneWidget);
    expect(find.text(ScanCommitBar.pendingLabelOf(1)), findsOneWidget);
  });

  testWidgets('la photo reste consultable une fois le ticket lu', (
    tester,
  ) async {
    await pumpScreen(tester, AsyncData(scanResult()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Photo'), findsOneWidget);
  });

  testWidgets('un ticket illisible explique quoi refaire', (tester) async {
    await pumpScreen(
      tester,
      AsyncError(const ScanUnreadableException(), StackTrace.empty),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.byType(ScanItemList), findsNothing);
  });

  testWidgets('une photo illisible n\'ouvre pas la revue', (tester) async {
    final image = Completer<Uint8List>();
    await pumpScreen(tester, const AsyncLoading(), image: image.future);

    image.completeError(const FileSystemException('illisible'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.byType(ScanItemList), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('un ticket sans article le dit', (tester) async {
    await pumpScreen(tester, AsyncData(scanResult(items: const [])));
    await tester.pump(const Duration(seconds: 2));

    expect(find.textContaining('Aucun article'), findsOneWidget);
    expect(find.byType(ScanCommitBar), findsNothing);
  });
}
