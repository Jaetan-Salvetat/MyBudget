import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/settings/screens/category_form_screen.dart';

const CategoryDisplay _defaults = CategoryDisplay(
  slug: 'alimentation',
  label: 'Alimentation',
  icon: 'restaurant',
  color: 0xFF4CAF50,
  groupKey: 'alimentation',
  groupLabel: 'Alimentation',
  type: TransactionType.expense,
);

const CategoryDisplay _customised = CategoryDisplay(
  slug: 'alimentation',
  label: 'Courses',
  icon: 'restaurant',
  color: 0xFF4CAF50,
  groupKey: 'alimentation',
  groupLabel: 'Alimentation',
  type: TransactionType.expense,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<CategoryFormResult? Function()> pushForm(
    WidgetTester tester, {
    CategoryDisplay initial = _defaults,
  }) async {
    CategoryFormResult? result;
    late BuildContext pageContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    unawaited(
      CategoryFormScreen.push(
        context: pageContext,
        initial: initial,
        defaults: _defaults,
      ).then((value) => result = value),
    );
    await tester.pumpAndSettle();

    return () => result;
  }

  testWidgets('names the edited category', (tester) async {
    await pushForm(tester);

    expect(find.textContaining('Alimentation'), findsWidgets);
  });

  testWidgets('an untouched form returns an empty customisation', (
    tester,
  ) async {
    final result = await pushForm(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(
      result(),
      isA<CategoryCustomisation>()
          .having((r) => r.name, 'name', isNull)
          .having((r) => r.icon, 'icon', isNull)
          .having((r) => r.color, 'color', isNull),
    );
  });

  testWidgets('a renamed category returns the new name', (tester) async {
    final result = await pushForm(tester);

    await tester.enterText(find.byType(TextField), 'Courses');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(
      result(),
      isA<CategoryCustomisation>().having((r) => r.name, 'name', 'Courses'),
    );
  });

  testWidgets('the reset action only shows on a customised category', (
    tester,
  ) async {
    await pushForm(tester);

    expect(find.text('Réinitialiser'), findsNothing);
  });

  testWidgets('resetting returns a reset result', (tester) async {
    final result = await pushForm(tester, initial: _customised);

    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();

    expect(result(), isA<CategoryReset>());
  });
}
