import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/layout_insets.dart';

void main() {
  Future<double> insetFor(WidgetTester tester, EdgeInsets viewPadding) async {
    late double inset;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(padding: viewPadding),
        child: Builder(
          builder: (BuildContext context) {
            inset = mainFlowBottomInset(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return inset;
  }

  group('mainFlowBottomInset', () {
    testWidgets('clears the nav pill on a device without gesture inset', (
      WidgetTester tester,
    ) async {
      final double inset = await insetFor(tester, EdgeInsets.zero);

      expect(inset, kNavPillFootprint + kNavPillClearance);
    });

    testWidgets('adds the bottom safe area on top of the pill', (
      WidgetTester tester,
    ) async {
      final double inset = await insetFor(
        tester,
        const EdgeInsets.only(bottom: 34),
      );

      expect(inset, kNavPillFootprint + kNavPillClearance + 34);
    });

    testWidgets('ignores insets that do not sit at the bottom', (
      WidgetTester tester,
    ) async {
      final double inset = await insetFor(
        tester,
        const EdgeInsets.only(top: 48, left: 12, right: 12),
      );

      expect(inset, kNavPillFootprint + kNavPillClearance);
    });
  });
}
