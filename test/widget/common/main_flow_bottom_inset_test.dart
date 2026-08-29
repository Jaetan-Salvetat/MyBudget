import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';

void main() {
  const List<FrostedNavItem> destinations = <FrostedNavItem>[
    FrostedNavItem(icon: Icons.dashboard_outlined, label: 'Accueil'),
    FrostedNavItem(icon: Icons.swap_vert_outlined, label: 'Transactions'),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required EdgeInsets viewPadding,
    bool folded = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: FrostedTheme.light(seedColor: const Color(0xFF2A55D3)),
        home: MediaQuery(
          data: MediaQueryData(padding: viewPadding),
          child: FrostedScaffold(
            bottomNavigationBar: FrostedBottomBar(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              folded: folded,
            ),
            body: Builder(
              builder: (BuildContext context) => ListView(
                padding: EdgeInsets.only(bottom: mainFlowBottomInset(context)),
                children: <Widget>[
                  const SizedBox(height: 2000),
                  Container(key: const Key('last'), height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<double> airUnderTheLastItem(WidgetTester tester) async {
    await tester.fling(find.byType(ListView), const Offset(0, -4000), 4000);
    await tester.pumpAndSettle();

    return tester.getRect(find.byType(FrostedBottomBar)).top -
        tester.getRect(find.byKey(const Key('last'))).bottom;
  }

  testWidgets('the body runs behind the bar, the last item clears it', (
    WidgetTester tester,
  ) async {
    await pump(tester, viewPadding: EdgeInsets.zero);

    expect(
      tester.getRect(find.byType(ListView)).bottom,
      tester.getRect(find.byType(FrostedScaffold)).bottom,
    );
    expect(await airUnderTheLastItem(tester), kMainFlowBottomClearance);
  });

  testWidgets('the gesture inset is counted once, by the bar', (
    WidgetTester tester,
  ) async {
    await pump(tester, viewPadding: const EdgeInsets.only(bottom: 34));

    expect(await airUnderTheLastItem(tester), kMainFlowBottomClearance);
  });

  testWidgets('folded away, the bar gives its room back to the body', (
    WidgetTester tester,
  ) async {
    await pump(tester, viewPadding: EdgeInsets.zero, folded: true);
    await tester.pumpAndSettle();

    expect(await airUnderTheLastItem(tester), kMainFlowBottomClearance);
  });
}
