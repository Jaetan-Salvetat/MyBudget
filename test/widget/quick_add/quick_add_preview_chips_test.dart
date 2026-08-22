import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_preview_chips.dart';

void main() {
  Future<void> pumpChips(
    WidgetTester tester, {
    String? amountLabel,
    QuickAddCategoryPreview? category,
    String? recurrenceLabel,
    bool isAnalyzing = false,
    VoidCallback? onPickCategory,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: QuickAddPreviewChips(
            amountLabel: amountLabel,
            category: category,
            recurrenceLabel: recurrenceLabel,
            isAnalyzing: isAnalyzing,
            onPickCategory: onPickCategory ?? () {},
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
    await pumpChips(tester);

    expect(find.byType(Chip), findsNothing);
    expect(find.textContaining('€'), findsNothing);
  });

  testWidgets('shows the amount as soon as it is known', (tester) async {
    await pumpChips(tester, amountLabel: '12,00 €');
    await tester.pumpAndSettle();

    expect(find.text('12,00 €'), findsOneWidget);
  });

  testWidgets('shows the amount before the category has landed', (
    tester,
  ) async {
    await pumpChips(tester, amountLabel: '12,00 €', isAnalyzing: true);
    await tester.pumpAndSettle();

    expect(find.text('12,00 €'), findsOneWidget);
    expect(find.text('Fast-food'), findsNothing);
  });

  testWidgets('shows the category once it lands', (tester) async {
    await pumpChips(tester, amountLabel: '12,00 €', category: category);
    await tester.pumpAndSettle();

    expect(find.text('Fast-food'), findsOneWidget);
    expect(find.byIcon(Symbols.restaurant_rounded), findsOneWidget);
  });

  testWidgets('shows the recurrence only when there is one', (tester) async {
    await pumpChips(tester, amountLabel: '13,99 €', category: category);
    await tester.pumpAndSettle();
    expect(find.text('Mensuel'), findsNothing);

    await pumpChips(
      tester,
      amountLabel: '13,99 €',
      category: category,
      recurrenceLabel: 'Mensuel',
    );
    await tester.pumpAndSettle();
    expect(find.text('Mensuel'), findsOneWidget);
  });

  testWidgets('tapping the category chip asks for a correction', (
    tester,
  ) async {
    var picked = 0;
    await pumpChips(
      tester,
      amountLabel: '12,00 €',
      category: category,
      onPickCategory: () => picked++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fast-food'));
    await tester.pumpAndSettle();

    expect(picked, 1);
  });

  testWidgets('an uncertain category still offers the correction', (
    tester,
  ) async {
    var picked = 0;
    await pumpChips(
      tester,
      amountLabel: '12,00 €',
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
}
