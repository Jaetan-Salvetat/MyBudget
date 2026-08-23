import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_avatar.dart';
import 'package:mybudget/ui/common/widgets/transaction_avatar.dart';

void main() {
  const categoryColor = Color(0xFF4CAF50);
  const badgeColor = Color(0xFF2196F3);

  final beneficiary = Beneficiary.fromModel(
    BeneficiaryModel.create(name: 'Jean Dupont', color: 0xFFE91E63),
  );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: child)),
  );

  BoxDecoration avatarDecoration(WidgetTester tester) =>
      tester
              .widget<Container>(
                find
                    .descendant(
                      of: find.byType(TransactionAvatar),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .decoration!
          as BoxDecoration;

  testWidgets('paints the category color and its icon without a beneficiary', (
    tester,
  ) async {
    await pump(
      tester,
      const TransactionAvatar(
        color: categoryColor,
        icon: Symbols.restaurant_rounded,
        badgeColor: badgeColor,
      ),
    );

    expect(avatarDecoration(tester).color, categoryColor);
    expect(
      tester.widget<Icon>(find.byIcon(Symbols.restaurant_rounded)).color,
      Colors.white,
    );
    expect(find.byType(BeneficiaryAvatar), findsNothing);
  });

  testWidgets('shows the beneficiary initials instead of the icon', (
    tester,
  ) async {
    await pump(
      tester,
      TransactionAvatar(
        color: categoryColor,
        icon: Symbols.restaurant_rounded,
        badgeColor: badgeColor,
        beneficiary: beneficiary,
      ),
    );

    expect(find.text('JD'), findsOneWidget);
    expect(find.byIcon(Symbols.restaurant_rounded), findsNothing);
  });

  testWidgets('keeps the same rounded square shape in both cases', (
    tester,
  ) async {
    const expected = BorderRadius.all(Radius.circular(10));

    await pump(
      tester,
      const TransactionAvatar(
        color: categoryColor,
        icon: Symbols.restaurant_rounded,
        badgeColor: badgeColor,
      ),
    );
    expect(avatarDecoration(tester).borderRadius, expected);

    await pump(
      tester,
      TransactionAvatar(
        color: categoryColor,
        icon: Symbols.restaurant_rounded,
        badgeColor: badgeColor,
        beneficiary: beneficiary,
      ),
    );
    expect(avatarDecoration(tester).borderRadius, expected);
  });

  testWidgets('never paints a shadow behind the avatar', (tester) async {
    await pump(
      tester,
      TransactionAvatar(
        color: categoryColor,
        icon: Symbols.restaurant_rounded,
        badgeColor: badgeColor,
        beneficiary: beneficiary,
        badgeLetter: 'M',
      ),
    );

    expect(avatarDecoration(tester).boxShadow, isNull);
  });

  testWidgets('renders the badge letter when one is given', (tester) async {
    await pump(
      tester,
      const TransactionAvatar(
        color: categoryColor,
        icon: Symbols.restaurant_rounded,
        badgeColor: badgeColor,
        badgeLetter: 'M',
      ),
    );

    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('renders no badge without a letter', (tester) async {
    await pump(
      tester,
      const TransactionAvatar(
        color: categoryColor,
        icon: Symbols.restaurant_rounded,
        badgeColor: badgeColor,
      ),
    );

    expect(find.byType(Text), findsNothing);
  });
}
