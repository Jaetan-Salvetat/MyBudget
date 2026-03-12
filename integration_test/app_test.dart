import 'package:integration_test/integration_test.dart';

import 'tests/navigation_dashboard_test.dart' as navigation;
import 'tests/accounts_test.dart' as accounts;
import 'tests/categories_test.dart' as categories;
import 'tests/beneficiaries_test.dart' as beneficiaries;
import 'tests/expenses_test.dart' as expenses;
import 'tests/revenues_test.dart' as revenues;
import 'tests/loans_test.dart' as loans;
import 'tests/settings_test.dart' as settings;
import 'tests/transfers_test.dart' as transfers;
import 'tests/e2e_test.dart' as e2e;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  navigation.main();
  accounts.main();
  categories.main();
  beneficiaries.main();
  expenses.main();
  revenues.main();
  loans.main();
  transfers.main();
  settings.main();
  e2e.main();
}
