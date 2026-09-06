import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> pumpView(
    WidgetTester tester, {
    required int index,
    bool disableAnimations = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: FrostedFadeThroughView(
            index: index,
            children: const <Widget>[
              _Counter(label: 'first'),
              _Counter(label: 'second'),
            ],
          ),
        ),
      ),
    );
  }

  double opacityOf(WidgetTester tester) {
    return tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(FrostedFadeThroughView),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;
  }

  int visibleIndexOf(WidgetTester tester) {
    return tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;
  }

  group('FrostedFadeThroughView glass', () {
    Future<void> pumpGlassView(WidgetTester tester, int index) {
      return tester.pumpWidget(
        MaterialApp(
          theme: FrostedTheme.dark(seedColor: const Color(0xFF7C5CFF)),
          home: FrostedFadeThroughView(
            index: index,
            children: const <Widget>[
              FrostedGlass(child: SizedBox.expand()),
              SizedBox.expand(),
            ],
          ),
        ),
      );
    }

    testWidgets('glass keeps its backdrop once the swap has settled', (
      WidgetTester tester,
    ) async {
      await pumpGlassView(tester, 0);
      await tester.pumpAndSettle();

      expect(tester.layers.whereType<BackdropFilterLayer>(), isNotEmpty);
    });

    testWidgets('glass drops its backdrop while the fade is in flight', (
      WidgetTester tester,
    ) async {
      await pumpGlassView(tester, 0);
      await tester.pumpAndSettle();

      await pumpGlassView(tester, 1);
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);

      await pumpGlassView(tester, 0);
      await tester.pumpAndSettle();

      expect(tester.layers.whereType<BackdropFilterLayer>(), isNotEmpty);
    });
  });

  group('FrostedFadeThroughView fade through', () {
    testWidgets('settles fully opaque', (WidgetTester tester) async {
      await pumpView(tester, index: 0);
      await tester.pumpAndSettle();

      expect(opacityOf(tester), 1);
    });

    testWidgets('holds the outgoing view while it fades out', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, index: 0);
      await tester.pumpAndSettle();

      await pumpView(tester, index: 1);
      await tester.pump(const Duration(milliseconds: 50));

      expect(visibleIndexOf(tester), 0);
      expect(opacityOf(tester), lessThan(1));
    });

    testWidgets('fades the incoming view in once the outgoing one is gone', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, index: 0);
      await tester.pumpAndSettle();

      await pumpView(tester, index: 1);
      await tester.pump(const Duration(milliseconds: 110));

      expect(visibleIndexOf(tester), 1);
      expect(opacityOf(tester), lessThan(1));
      expect(opacityOf(tester), greaterThan(0));

      await tester.pumpAndSettle();

      expect(opacityOf(tester), 1);
    });

    testWidgets('keeps the state of the views it steps away from', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, index: 0);
      await tester.pumpAndSettle();

      await tester.tap(find.text('first 0'));
      await tester.pumpAndSettle();
      expect(find.text('first 1'), findsOneWidget);

      await pumpView(tester, index: 1);
      await tester.pumpAndSettle();
      await pumpView(tester, index: 0);
      await tester.pumpAndSettle();

      expect(find.text('first 1'), findsOneWidget);
    });

    testWidgets('swaps instantly when the platform disables animations', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, index: 0, disableAnimations: true);
      await tester.pumpAndSettle();

      await pumpView(tester, index: 1, disableAnimations: true);
      await tester.pump();

      expect(visibleIndexOf(tester), 1);
      expect(opacityOf(tester), 1);
    });

    testWidgets('takes focus on the view it swaps in only once settled', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      Future<void> pumpFocusView(int index) {
        return tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: FrostedFadeThroughView(
                index: index,
                children: <Widget>[
                  TextField(focusNode: node),
                  const SizedBox.expand(),
                ],
              ),
            ),
          ),
        );
      }

      await pumpFocusView(0);
      await tester.pumpAndSettle();
      await pumpFocusView(1);
      await tester.pumpAndSettle();

      await pumpFocusView(0);
      await tester.pump();
      node.requestFocus();
      await tester.pump();

      expect(node.hasFocus, isFalse);

      await tester.pump(FrostedFadeThroughView.transitionDuration);
      node.requestFocus();
      await tester.pump();

      expect(node.hasFocus, isTrue);
    });

    testWidgets('a mid-flight change fades out whatever is on screen', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, index: 0);
      await tester.pumpAndSettle();

      await pumpView(tester, index: 1);
      await tester.pump(const Duration(milliseconds: 150));
      expect(visibleIndexOf(tester), 1);

      await pumpView(tester, index: 0);
      await tester.pump(const Duration(milliseconds: 50));

      expect(visibleIndexOf(tester), 1);

      await tester.pumpAndSettle();

      expect(visibleIndexOf(tester), 0);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter({required this.label});

  final String label;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _taps++),
      child: Center(child: Text('${widget.label} $_taps')),
    );
  }
}
