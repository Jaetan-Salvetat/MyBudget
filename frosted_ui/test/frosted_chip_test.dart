import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  const Color seed = Color(0xFF7C5CFF);
  const Key avatarKey = Key('avatar');

  Future<void> pump(WidgetTester tester, Widget chip) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.dark(seedColor: seed),
        home: Scaffold(body: Center(child: chip)),
      ),
    );
  }

  group('FrostedChip.filter avatar', () {
    testWidgets('shows the avatar while unselected', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FrostedChip.filter(
          label: 'Courses',
          selected: false,
          avatar: const SizedBox(key: avatarKey, width: 12, height: 12),
          onSelected: (_) {},
        ),
      );

      expect(find.byKey(avatarKey), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('the check replaces the avatar once selected', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        FrostedChip.filter(
          label: 'Courses',
          selected: true,
          avatar: const SizedBox(key: avatarKey, width: 12, height: 12),
          onSelected: (_) {},
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byKey(avatarKey), findsNothing);
    });

    testWidgets('toggles through onSelected', (WidgetTester tester) async {
      final List<bool> log = <bool>[];
      await pump(
        tester,
        FrostedChip.filter(
          label: 'Courses',
          selected: false,
          avatar: const SizedBox(key: avatarKey, width: 12, height: 12),
          onSelected: log.add,
        ),
      );

      await tester.tap(find.byType(FrostedChip));
      await tester.pump();

      expect(log, <bool>[true]);
    });
  });
}
