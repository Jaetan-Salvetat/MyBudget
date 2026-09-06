import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';

void main() {
  const categoryColor = Color(0xFF4CAF50);
  const beneficiaryColor = 0xFFE91E63;

  final beneficiary = BeneficiaryModel.create(
    name: 'Jean Dupont',
    color: beneficiaryColor,
  );
  final colorlessBeneficiary = BeneficiaryModel.create(name: 'Erwin');

  Future<void> pump(WidgetTester tester, BeneficiaryModel? beneficiary) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: TransactionAvatar(
              color: categoryColor,
              icon: Symbols.restaurant_rounded,
              beneficiary: beneficiary,
            ),
          ),
        ),
      );

  List<Container> containersOf(WidgetTester tester) => tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(TransactionAvatar),
          matching: find.byType(Container),
        ),
      )
      .toList();

  BoxDecoration decorationOf(Container container) =>
      container.decoration! as BoxDecoration;

  testWidgets('always shows the category icon over the category color', (
    tester,
  ) async {
    await pump(tester, beneficiary);

    expect(decorationOf(containersOf(tester).first).color, categoryColor);
    expect(
      tester.widget<Icon>(find.byIcon(Symbols.restaurant_rounded)).color,
      Colors.white,
    );
  });

  testWidgets('badges the avatar with the beneficiary initials', (
    tester,
  ) async {
    await pump(tester, beneficiary);

    expect(find.text('JD'), findsOneWidget);
  });

  testWidgets('tints the badge with the beneficiary color', (tester) async {
    await pump(tester, beneficiary);

    expect(
      decorationOf(containersOf(tester).last).color,
      const Color(beneficiaryColor),
    );
  });

  testWidgets('falls back to the theme color for a colorless beneficiary', (
    tester,
  ) async {
    await pump(tester, colorlessBeneficiary);

    expect(find.text('Er'), findsOneWidget);
    expect(
      decorationOf(containersOf(tester).last).color,
      isNot(const Color(0x00000000)),
    );
  });

  testWidgets('shows no badge without a beneficiary', (tester) async {
    await pump(tester, null);

    expect(find.byType(Text), findsNothing);
    expect(containersOf(tester), hasLength(1));
  });
}
