import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/services/data/legacy_loan_defaults_migration.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

class FakeLoanModel extends Fake implements LoanModel {}

LoanModel _storedLoan({
  required String purposeId,
  required bool hasIndemnityClause,
}) => LoanModel(
  name: 'Prêt auto',
  amount: 10000,
  lenderName: 'Banque',
  accountId: 1,
  dayOfMonth: 5,
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime(2030, 1, 1),
  interestRate: 3.5,
  duration: 60,
  deferralTypeId: '',
  purposeId: purposeId,
  hasIndemnityClause: hasIndemnityClause,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLoanRepository loans;
  late LegacyLoanDefaultsMigration migration;

  setUpAll(() => registerFallbackValue(FakeLoanModel()));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    loans = MockLoanRepository();
    when(() => loans.update(any())).thenReturn(1);
    migration = LegacyLoanDefaultsMigration(loans: loans);
  });

  test('fills the defaults a v0.7.5 loan never stored', () async {
    when(() => loans.getAll()).thenReturn([
      _storedLoan(purposeId: '', hasIndemnityClause: false),
    ]);

    await migration.run();

    final migrated =
        verify(() => loans.update(captureAny())).captured.single as LoanModel;
    expect(migrated.purposeId, LoanPurpose.other.name);
    expect(migrated.deferralTypeId, LoanDeferralType.partial.name);
    expect(migrated.hasIndemnityClause, isTrue);
  });

  test('leaves a loan created by the current version untouched', () async {
    when(() => loans.getAll()).thenReturn([
      _storedLoan(purposeId: LoanPurpose.car.name, hasIndemnityClause: false),
    ]);

    await migration.run();

    verifyNever(() => loans.update(any()));
  });

  test('marks the migration done so it never runs twice', () async {
    when(() => loans.getAll()).thenReturn([
      _storedLoan(purposeId: '', hasIndemnityClause: false),
    ]);

    await migration.run();
    expect(PreferencesService.isLegacyLoanDefaultsMigrationDone(), isTrue);

    await migration.run();
    verify(() => loans.getAll()).called(1);
  });
}
