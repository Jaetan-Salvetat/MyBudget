import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/values/loan.dart';
import 'package:mybudget/data/model/loan_model.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/data/repository/loan_repository.dart';
import 'package:mybudget/ui/loans/providers/loan_edit_provider.dart';

import '../../../helpers/loan_test_factory.dart';

class MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  group('LoanEditNotifier', () {
    late Loan testLoan;
    late LoanModel testLoanModel;

    setUp(() {
      testLoanModel = LoanModel.create(
        name: 'Prêt Test',
        amount: 10000,
        lenderName: 'Banque Test',
        accountId: 1,
        dayOfMonth: 15,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2025, 1, 1),
        interestRate: 5.0,
        duration: 12,
        repaymentType: LoanRepaymentType.amortizable,
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.fixed,
        insuranceValue: 25.0,
        insuranceCalculationMode: InsuranceCalculationMode.initialCapital,
      );

      testLoan = buildTestLoan(testLoanModel);
    });

    ProviderContainer makeContainer() {
      final repository = MockLoanRepository();
      when(() => repository.get(testLoanModel.id)).thenReturn(testLoanModel);
      return ProviderContainer(
        overrides: [loanRepositoryProvider.overrideWithValue(repository)],
      );
    }

    test('should initialize with values from initial loan', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(loanEditProvider(testLoan));

      expect(state.name, 'Prêt Test');
      expect(state.lenderName, 'Banque Test');
      expect(state.insuranceValue, 25.0);
      expect(state.selectedAccountId, 1);
      expect(state.dayOfMonth, 15);
      expect(state.insuranceType, LoanInsuranceType.fixed);
      expect(state.insuranceCalcMode, InsuranceCalculationMode.initialCapital);
    });

    test('should initialize with 0 insurance value when none', () {
      final loanWithoutInsurance = LoanModel.create(
        name: 'Prêt Test',
        amount: 10000,
        lenderName: 'Banque Test',
        accountId: 1,
        dayOfMonth: 15,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2025, 1, 1),
        interestRate: 5.0,
        duration: 12,
        repaymentType: LoanRepaymentType.amortizable,
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalculationMode: InsuranceCalculationMode.initialCapital,
      );

      final loan = buildTestLoan(loanWithoutInsurance);
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(loanEditProvider(loan)).insuranceValue, 0.0);
    });

    test('should expose read-only fields from initial loan', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(loanEditProvider(testLoan));

      expect(state.capital, 10000);
      expect(state.signatureDate, DateTime(2024, 1, 1));
      expect(state.endDate, DateTime(2025, 1, 15));
      expect(state.duration, 12);
      expect(state.interestRate, 5.0);
      expect(state.repaymentType, LoanRepaymentType.amortizable);
      expect(state.deferredMonths, 0);
    });

    test('should update name via setter', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container
          .read(loanEditProvider(testLoan).notifier)
          .setName('Nouveau Nom');

      expect(container.read(loanEditProvider(testLoan)).name, 'Nouveau Nom');
    });

    test('should update lender name via setter', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container
          .read(loanEditProvider(testLoan).notifier)
          .setLenderName('Nouvelle Banque');

      expect(
        container.read(loanEditProvider(testLoan)).lenderName,
        'Nouvelle Banque',
      );
    });

    test('should update account id', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(loanEditProvider(testLoan).notifier).setAccountId(5);

      expect(container.read(loanEditProvider(testLoan)).selectedAccountId, 5);
    });

    test('should update day of month and clamp between 1 and 31', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanEditProvider(testLoan).notifier);

      notifier.setDayOfMonth(25);
      expect(container.read(loanEditProvider(testLoan)).dayOfMonth, 25);

      notifier.setDayOfMonth(0);
      expect(container.read(loanEditProvider(testLoan)).dayOfMonth, 1);

      notifier.setDayOfMonth(35);
      expect(container.read(loanEditProvider(testLoan)).dayOfMonth, 31);
    });

    test('should update insurance type', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container
          .read(loanEditProvider(testLoan).notifier)
          .setInsuranceType(LoanInsuranceType.percentage);

      expect(
        container.read(loanEditProvider(testLoan)).insuranceType,
        LoanInsuranceType.percentage,
      );
    });

    test('should update insurance calculation mode', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container
          .read(loanEditProvider(testLoan).notifier)
          .setInsuranceCalculationMode(
            InsuranceCalculationMode.remainingCapital,
          );

      expect(
        container.read(loanEditProvider(testLoan)).insuranceCalcMode,
        InsuranceCalculationMode.remainingCapital,
      );
    });

    test('should parse insurance value with comma support', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanEditProvider(testLoan).notifier);

      notifier.setInsuranceValue('30.5');
      expect(container.read(loanEditProvider(testLoan)).insuranceValue, 30.5);

      notifier.setInsuranceValue('35,75');
      expect(container.read(loanEditProvider(testLoan)).insuranceValue, 35.75);

      notifier.setInsuranceValue('invalid');
      expect(container.read(loanEditProvider(testLoan)).insuranceValue, 0.0);
    });

    test('should calculate monthly insurance payment for fixed type', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanEditProvider(testLoan).notifier);
      notifier.setInsuranceType(LoanInsuranceType.fixed);
      notifier.setInsuranceValue('40');

      expect(
        container.read(loanEditProvider(testLoan)).monthlyInsurancePayment,
        40.0,
      );
    });

    test('should calculate monthly insurance payment for percentage type', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanEditProvider(testLoan).notifier);
      notifier.setInsuranceType(LoanInsuranceType.percentage);
      notifier.setInsuranceValue('0.36');

      expect(
        container.read(loanEditProvider(testLoan)).monthlyInsurancePayment,
        closeTo(3.0, 0.01),
      );
    });

    test('should return 0 for monthly insurance payment when type is none', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanEditProvider(testLoan).notifier);
      notifier.setInsuranceType(LoanInsuranceType.none);
      notifier.setInsuranceValue('50');

      expect(
        container.read(loanEditProvider(testLoan)).monthlyInsurancePayment,
        0.0,
      );
    });

    test('should return 0 for monthly insurance payment when value is 0', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanEditProvider(testLoan).notifier);
      notifier.setInsuranceType(LoanInsuranceType.fixed);
      notifier.setInsuranceValue('0');

      expect(
        container.read(loanEditProvider(testLoan)).monthlyInsurancePayment,
        0.0,
      );
    });

    test('should validate correctly when all required fields are filled', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(loanEditProvider(testLoan)).isValid, true);
    });

    test('should not validate when name is empty', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(loanEditProvider(testLoan).notifier).setName('');

      expect(container.read(loanEditProvider(testLoan)).isValid, false);
    });

    test('should not validate when lender name is empty', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(loanEditProvider(testLoan).notifier).setLenderName('');

      expect(container.read(loanEditProvider(testLoan)).isValid, false);
    });

    test('should not validate when account id is invalid', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(loanEditProvider(testLoan).notifier).setAccountId(-1);

      expect(container.read(loanEditProvider(testLoan)).isValid, false);
    });

    test('should trim whitespace from name and lender name in final model', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanEditProvider(testLoan).notifier);
      notifier.setName('  Nom avec espaces  ');
      notifier.setLenderName('  Banque avec espaces  ');

      final model = notifier.createUpdatedLoanModel();
      expect(model.name, 'Nom avec espaces');
      expect(model.lenderName, 'Banque avec espaces');
    });

    test('should create updated loan model with modified values', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(loanEditProvider(testLoan).notifier);
      notifier.setName('Nouveau Nom');
      notifier.setLenderName('Nouvelle Banque');
      notifier.setAccountId(3);
      notifier.setDayOfMonth(20);
      notifier.setInsuranceType(LoanInsuranceType.percentage);
      notifier.setInsuranceValue('0.5');
      notifier.setInsuranceCalculationMode(
        InsuranceCalculationMode.remainingCapital,
      );

      final updatedModel = notifier.createUpdatedLoanModel();

      expect(updatedModel.name, 'Nouveau Nom');
      expect(updatedModel.lenderName, 'Nouvelle Banque');
      expect(updatedModel.accountId, 3);
      expect(updatedModel.dayOfMonth, 20);
      expect(updatedModel.insuranceType, LoanInsuranceType.percentage);
      expect(updatedModel.insuranceValue, 0.5);
      expect(
        updatedModel.insuranceCalculationMode,
        InsuranceCalculationMode.remainingCapital,
      );

      expect(updatedModel.amount, testLoanModel.amount);
      expect(updatedModel.startDate, testLoanModel.startDate);
      expect(updatedModel.endDate, testLoanModel.endDate);
      expect(updatedModel.duration, testLoanModel.duration);
      expect(updatedModel.interestRate, testLoanModel.interestRate);
      expect(updatedModel.repaymentType, testLoanModel.repaymentType);
      expect(updatedModel.deferredMonths, testLoanModel.deferredMonths);
    });

    test('should handle loan with deferred months', () {
      final loanWithDeferred = LoanModel.create(
        name: 'PTZ',
        amount: 50000,
        lenderName: 'État',
        accountId: 2,
        dayOfMonth: 1,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2034, 1, 1),
        interestRate: 0.0,
        duration: 120,
        repaymentType: LoanRepaymentType.amortizable,
        deferredMonths: 60,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalculationMode: InsuranceCalculationMode.initialCapital,
      );

      final loan = buildTestLoan(loanWithDeferred);
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(loanEditProvider(loan)).deferredMonths, 60);
    });

    test('should handle in fine loan type', () {
      final inFineLoan = LoanModel.create(
        name: 'Prêt In Fine',
        amount: 100000,
        lenderName: 'Banque Privée',
        accountId: 3,
        dayOfMonth: 5,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2034, 1, 1),
        interestRate: 2.5,
        duration: 120,
        repaymentType: LoanRepaymentType.inFine,
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.percentage,
        insuranceValue: 0.3,
        insuranceCalculationMode: InsuranceCalculationMode.initialCapital,
      );

      final loan = buildTestLoan(inFineLoan);
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        container.read(loanEditProvider(loan)).repaymentType,
        LoanRepaymentType.inFine,
      );
    });
  });
}
