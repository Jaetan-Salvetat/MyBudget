import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_draft_line.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_shimmer.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  Future<void> pumpLine(
    WidgetTester tester, {
    double? amount,
    bool isIncome = false,
    QuickAddCategoryPreview? category,
    String? recurrenceLabel,
    String? dateLabel,
    bool isStale = false,
    VoidCallback? onPickCategory,
    VoidCallback? onPickDate,
    VoidCallback? onPickFrequency,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: QuickAddDraftLine(
            amount: amount,
            isIncome: isIncome,
            category: category,
            recurrenceLabel: recurrenceLabel,
            dateLabel: dateLabel,
            isStale: isStale,
            onPickCategory: onPickCategory ?? () {},
            onPickDate: onPickDate ?? () {},
            onPickFrequency: onPickFrequency ?? () {},
          ),
        ),
      ),
    );
  }

  const category = QuickAddCategoryPreview(
    label: 'Fast-food',
    icon: Symbols.restaurant_rounded,
    color: Color(0xFFF44336),
    isUncertain: false,
  );

  testWidgets('shows nothing while the draft carries nothing', (tester) async {
    await pumpLine(tester);

    expect(find.textContaining('€', findRichText: true), findsNothing);
  });

  testWidgets('shows the amount as soon as it is known', (tester) async {
    await pumpLine(tester, amount: 12);
    await tester.pumpAndSettle();

    expect(
      find.text(MoneyFormatter.format(12), findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('an income reads with its plus sign', (tester) async {
    await pumpLine(tester, amount: 2500, isIncome: true);
    await tester.pumpAndSettle();

    expect(find.textContaining('+', findRichText: true), findsOneWidget);
  });

  testWidgets('shows the amount before the category has landed', (
    tester,
  ) async {
    await pumpLine(tester, amount: 12, isStale: true);
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.text(MoneyFormatter.format(12), findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Fast-food'), findsNothing);
  });

  testWidgets('the pending category shimmers instead of sitting still', (
    tester,
  ) async {
    await pumpLine(tester, amount: 12, isStale: true);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(QuickAddShimmer), findsOneWidget);
  });

  testWidgets('a landed category brings a zero amount rather than a gap', (
    tester,
  ) async {
    await pumpLine(tester, category: category);
    await tester.pumpAndSettle();

    expect(
      find.text(MoneyFormatter.format(0), findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('the zero placeholder never reads as an income', (tester) async {
    await pumpLine(tester, category: category, isIncome: true);
    await tester.pumpAndSettle();

    expect(find.textContaining('+', findRichText: true), findsNothing);
  });

  testWidgets('the placeholder gives way to the amount once it is typed', (
    tester,
  ) async {
    await pumpLine(tester, category: category);
    await tester.pumpAndSettle();

    await pumpLine(tester, amount: 12, category: category);
    await tester.pumpAndSettle();

    expect(
      find.text(MoneyFormatter.format(12), findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text(MoneyFormatter.format(0), findRichText: true),
      findsNothing,
    );
  });

  testWidgets('shows the category once it lands', (tester) async {
    await pumpLine(tester, amount: 12, category: category);
    await tester.pumpAndSettle();

    expect(find.text('Fast-food'), findsOneWidget);
    expect(find.byIcon(Symbols.restaurant_rounded), findsOneWidget);
    expect(find.byType(QuickAddShimmer), findsNothing);
  });

  testWidgets('tapping the category asks for a correction', (tester) async {
    var picked = 0;
    await pumpLine(
      tester,
      amount: 12,
      category: category,
      onPickCategory: () => picked++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fast-food'));
    await tester.pumpAndSettle();

    expect(picked, 1);
  });

  testWidgets('a stale reading cannot be corrected', (tester) async {
    var picked = 0;
    await pumpLine(
      tester,
      amount: 12,
      category: category,
      isStale: true,
      onPickCategory: () => picked++,
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Fast-food'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 600));

    expect(picked, 0);
  });

  testWidgets('an uncertain category still offers the correction', (
    tester,
  ) async {
    var picked = 0;
    await pumpLine(
      tester,
      amount: 12,
      category: const QuickAddCategoryPreview(
        label: 'Divers',
        icon: Symbols.category_rounded,
        color: Color(0xFF9E9E9E),
        isUncertain: true,
      ),
      onPickCategory: () => picked++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Divers'));
    await tester.pumpAndSettle();

    expect(picked, 1);
  });

  testWidgets('shows the day the transaction will land on', (tester) async {
    await pumpLine(tester, amount: 12, dateLabel: 'Hier');
    await tester.pumpAndSettle();

    expect(find.textContaining('hier'), findsOneWidget);
  });

  testWidgets('tapping the date asks for another day', (tester) async {
    var picked = 0;
    await pumpLine(
      tester,
      amount: 12,
      dateLabel: 'Hier',
      onPickDate: () => picked++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('hier'));
    await tester.pumpAndSettle();

    expect(picked, 1);
  });

  testWidgets('the date stays editable while the model catches up', (
    tester,
  ) async {
    var picked = 0;
    await pumpLine(
      tester,
      amount: 12,
      dateLabel: 'Hier',
      category: category,
      isStale: true,
      onPickDate: () => picked++,
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.textContaining('hier'));
    await tester.pump(const Duration(milliseconds: 600));

    expect(picked, 1);
  });

  testWidgets('tapping the recurrence asks for another rhythm', (tester) async {
    var picked = 0;
    await pumpLine(
      tester,
      amount: 13.99,
      category: category,
      recurrenceLabel: 'Ponctuel',
      onPickFrequency: () => picked++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('ponctuel'));
    await tester.pumpAndSettle();

    expect(picked, 1);
  });

  testWidgets('a stale recurrence cannot be corrected', (tester) async {
    var picked = 0;
    await pumpLine(
      tester,
      amount: 13.99,
      category: category,
      recurrenceLabel: 'Ponctuel',
      isStale: true,
      onPickFrequency: () => picked++,
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.textContaining('ponctuel'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 600));

    expect(picked, 0);
  });

  testWidgets('shows the recurrence only when there is one', (tester) async {
    await pumpLine(tester, amount: 13.99, category: category);
    await tester.pumpAndSettle();
    expect(find.textContaining('mensuel'), findsNothing);

    await pumpLine(
      tester,
      amount: 13.99,
      category: category,
      recurrenceLabel: 'Mensuel',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('mensuel'), findsOneWidget);
  });
}
