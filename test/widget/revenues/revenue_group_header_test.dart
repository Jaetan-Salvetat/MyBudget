import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/core/services/revenue_grouping_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_group_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RevenueModel revenue(double amount) => RevenueModel.create(
    name: 'Salaire',
    amount: amount,
    startDate: DateTime(2026, 8, 5),
    accountId: 1,
    frequency: Frequency.monthly.label,
  );

  Future<void> pump(WidgetTester tester, RevenueGroup group) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RevenueGroupHeader(
            group: group,
            axis: RevenueGroupBy.beneficiary,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the label, the total and the share', (tester) async {
    await pump(
      tester,
      RevenueGroup(
        identity: const RevenueGroupIdentity(key: '1', label: 'Alex'),
        items: [revenue(2000)],
        total: 2000,
        share: 0.625,
      ),
    );

    expect(find.text('ALEX'), findsOneWidget);
    expect(find.textContaining('63 %'), findsOneWidget);
    expect(find.textContaining('2'), findsWidgets);
  });

  testWidgets('hides the share when the group holds everything', (
    tester,
  ) async {
    await pump(
      tester,
      RevenueGroup(
        identity: const RevenueGroupIdentity(key: '1', label: 'Alex'),
        items: [revenue(2000)],
        total: 2000,
        share: 1,
      ),
    );

    expect(find.textContaining('%'), findsNothing);
  });
}
