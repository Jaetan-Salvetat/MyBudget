import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/build_flavor.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/ui/settings/help_content.dart';
import 'package:mybudget/ui/settings/models/help_topic.dart';
import 'package:mybudget/ui/settings/screens/beneficiaries_screen.dart';
import 'package:mybudget/ui/settings/screens/categories_screen.dart';
import 'package:mybudget/ui/settings/screens/help_screen.dart';
import 'package:mybudget/ui/settings/screens/quick_add_engine_screen.dart';
import 'package:mybudget/ui/settings/screens/theme_screen.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    BuildFlavor flavor = BuildFlavor.prod,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [buildFlavorProvider.overrideWithValue(flavor)],
        child: MaterialApp(theme: AppTheme.dark(), home: const HelpScreen()),
      ),
    );
  }

  final HelpChapter firstChapter = helpChapters.first;
  final HelpTopic firstTopic = firstChapter.topics.first;

  group('HelpScreen', () {
    testWidgets('affiche l\'intitulé de chaque chapitre', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.text(firstChapter.label), findsOneWidget);
    });

    testWidgets('présente les sujets repliés, résumé visible', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.text(firstTopic.title), findsOneWidget);
      expect(find.text(firstTopic.summary), findsOneWidget);
      expect(find.text(firstTopic.paragraphs.first), findsNothing);
    });

    testWidgets('toucher un sujet révèle son contenu', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text(firstTopic.title));
      await tester.pumpAndSettle();

      for (final String paragraph in firstTopic.paragraphs) {
        expect(find.text(paragraph), findsOneWidget);
      }
    });

    testWidgets('un sujet ouvert propose son action', (
      WidgetTester tester,
    ) async {
      final HelpTopic acting = helpChapters
          .expand((HelpChapter chapter) => chapter.topics)
          .firstWhere((HelpTopic topic) => topic.action != null);

      await pump(tester);
      await tester.scrollUntilVisible(find.text(acting.title), 200);
      await tester.tap(find.text(acting.title));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FrostedButton, acting.action!.label),
        findsOneWidget,
      );
    });

    testWidgets('le store retire les actions vers un écran qu\'il masque', (
      WidgetTester tester,
    ) async {
      final HelpTopic acting = helpChapters
          .expand((HelpChapter chapter) => chapter.topics)
          .firstWhere(
            (HelpTopic topic) =>
                topic.action?.destination == HelpDestination.quickAddEngine,
          );

      await pump(tester, flavor: BuildFlavor.store);
      await tester.scrollUntilVisible(find.text(acting.title), 200);
      await tester.tap(find.text(acting.title));
      await tester.pumpAndSettle();

      expect(find.text(acting.paragraphs.first), findsOneWidget);
      expect(
        find.widgetWithText(FrostedButton, acting.action!.label),
        findsNothing,
      );
    });

    testWidgets('un seul sujet reste ouvert à la fois', (
      WidgetTester tester,
    ) async {
      final HelpTopic second = firstChapter.topics[1];

      await pump(tester);
      await tester.tap(find.text(firstTopic.title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(second.title));
      await tester.pumpAndSettle();

      expect(find.text(second.paragraphs.first), findsOneWidget);
      expect(find.text(firstTopic.paragraphs.first), findsNothing);
    });
  });

  group('destinations', () {
    test('chaque destination mène à son écran', () {
      final Map<HelpDestination, Matcher> expected = <HelpDestination, Matcher>{
        HelpDestination.categories: isA<CategoriesScreen>(),
        HelpDestination.beneficiaries: isA<BeneficiariesScreen>(),
        HelpDestination.quickAddEngine: isA<QuickAddEngineScreen>(),
        HelpDestination.theme: isA<ThemeScreen>(),
      };

      expect(expected.keys, HelpDestination.values);

      expected.forEach((HelpDestination destination, Matcher matcher) {
        expect(helpDestinationScreen(destination), matcher);
      });
    });
  });
}
