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
  const ringColor = Color(0xFFFF9800);
  const fallbackColor = Color(0xFF9C27B0);

  final beneficiary = Beneficiary.fromModel(
    BeneficiaryModel.create(name: 'Jean Dupont', color: 0xFFE91E63),
  );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: child)),
  );

  BoxDecoration decorationOf(WidgetTester tester, Finder finder) =>
      tester.widget<Container>(finder).decoration! as BoxDecoration;

  Finder ringContainer() => find
      .descendant(
        of: find.byType(TransactionAvatar),
        matching: find.byType(Container),
      )
      .first;

  group('category variant', () {
    testWidgets('paints the category color and icon', (tester) async {
      await pump(
        tester,
        TransactionAvatar.category(
          color: categoryColor,
          icon: Symbols.restaurant_rounded,
          badgeColor: badgeColor,
        ),
      );

      expect(decorationOf(tester, ringContainer()).color, categoryColor);
      expect(
        tester.widget<Icon>(find.byIcon(Symbols.restaurant_rounded)).color,
        Colors.white,
      );
    });

    testWidgets('uses a rounded square shape', (tester) async {
      await pump(
        tester,
        TransactionAvatar.category(
          color: categoryColor,
          icon: Symbols.restaurant_rounded,
          badgeColor: badgeColor,
        ),
      );

      expect(
        decorationOf(tester, ringContainer()).borderRadius,
        BorderRadius.circular(10),
      );
    });
  });

  group('beneficiary variant', () {
    testWidgets('shows the beneficiary avatar when one is given', (
      tester,
    ) async {
      await pump(
        tester,
        TransactionAvatar.beneficiary(
          beneficiary: beneficiary,
          fallbackColor: fallbackColor,
          fallbackIcon: Symbols.savings_rounded,
          badgeColor: badgeColor,
        ),
      );

      expect(find.byType(BeneficiaryAvatar), findsOneWidget);
      expect(find.text('JD'), findsOneWidget);
      expect(find.byIcon(Symbols.savings_rounded), findsNothing);
    });

    testWidgets('falls back to the icon when there is no beneficiary', (
      tester,
    ) async {
      await pump(
        tester,
        TransactionAvatar.beneficiary(
          beneficiary: null,
          fallbackColor: fallbackColor,
          fallbackIcon: Symbols.savings_rounded,
          badgeColor: badgeColor,
        ),
      );

      expect(find.byType(BeneficiaryAvatar), findsNothing);
      expect(
        tester.widget<Icon>(find.byIcon(Symbols.savings_rounded)).color,
        fallbackColor,
      );
    });

    testWidgets('uses a circular shape', (tester) async {
      await pump(
        tester,
        TransactionAvatar.beneficiary(
          beneficiary: null,
          fallbackColor: fallbackColor,
          fallbackIcon: Symbols.savings_rounded,
          badgeColor: badgeColor,
        ),
      );

      expect(
        decorationOf(tester, ringContainer()).borderRadius,
        BorderRadius.circular(16),
      );
    });
  });

  group('chrome shared by both variants', () {
    testWidgets('draws no ring when no ring color is given', (tester) async {
      await pump(
        tester,
        TransactionAvatar.category(
          color: categoryColor,
          icon: Symbols.restaurant_rounded,
          badgeColor: badgeColor,
        ),
      );

      expect(decorationOf(tester, ringContainer()).boxShadow, isNull);
    });

    testWidgets('draws a surface gap then the ring when a color is given', (
      tester,
    ) async {
      await pump(
        tester,
        TransactionAvatar.category(
          color: categoryColor,
          icon: Symbols.restaurant_rounded,
          badgeColor: badgeColor,
          ringColor: ringColor,
        ),
      );

      final shadows = decorationOf(tester, ringContainer()).boxShadow!;
      expect(shadows, hasLength(2));
      expect(shadows.last.color, ringColor);
      expect(shadows.first.spreadRadius, lessThan(shadows.last.spreadRadius));
    });

    testWidgets('renders the badge letter when one is given', (tester) async {
      await pump(
        tester,
        TransactionAvatar.category(
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
        TransactionAvatar.category(
          color: categoryColor,
          icon: Symbols.restaurant_rounded,
          badgeColor: badgeColor,
        ),
      );

      expect(find.byType(Text), findsNothing);
    });
  });
}
