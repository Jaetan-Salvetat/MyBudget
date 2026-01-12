import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/domain/loan.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';
import 'package:mybudget/core/services/loan_payment_breakdown_service.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/loans/viewmodels/loan_edit_viewmodel.dart';

void main() {
  group('LoanEditViewModel', () {
    late Loan testLoan;
    late LoanModel testLoanModel;

    setUp(() {
      // Créer un LoanModel de test
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

      // Créer l'entité Loan de domaine
      const calculationService = LoanCalculationService();
      const breakdownService = LoanPaymentBreakdownService(calculationService);
      testLoan = Loan(testLoanModel, calculationService, breakdownService);
    });

    test('should initialize with values from initial loan', () {
      final viewModel = LoanEditViewModel(testLoan);

      expect(viewModel.nameController.text, 'Prêt Test');
      expect(viewModel.lenderController.text, 'Banque Test');
      expect(viewModel.insuranceValueController.text, '25.0');
      expect(viewModel.selectedAccountId, 1);
      expect(viewModel.dayOfMonth, 15);
      expect(viewModel.insuranceType, LoanInsuranceType.fixed);
      expect(
        viewModel.insuranceCalcMode,
        InsuranceCalculationMode.initialCapital,
      );

      viewModel.dispose();
    });

    test('should initialize with empty insurance value when none', () {
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

      const calculationService = LoanCalculationService();
      const breakdownService = LoanPaymentBreakdownService(calculationService);
      final loan = Loan(loanWithoutInsurance, calculationService, breakdownService);

      final viewModel = LoanEditViewModel(loan);

      expect(viewModel.insuranceValueController.text, '');

      viewModel.dispose();
    });

    test('should expose read-only fields from initial loan', () {
      final viewModel = LoanEditViewModel(testLoan);

      expect(viewModel.capital, 10000);
      expect(viewModel.signatureDate, DateTime(2024, 1, 1));
      expect(viewModel.endDate, DateTime(2025, 1, 1));
      expect(viewModel.duration, 12);
      expect(viewModel.interestRate, 5.0);
      expect(viewModel.repaymentType, LoanRepaymentType.amortizable);
      expect(viewModel.deferredMonths, 0);

      viewModel.dispose();
    });

    test('should update name when controller changes', () {
      final viewModel = LoanEditViewModel(testLoan);
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.nameController.text = 'Nouveau Nom';

      expect(viewModel.name, 'Nouveau Nom');
      expect(notified, true);

      viewModel.dispose();
    });

    test('should update lender name when controller changes', () {
      final viewModel = LoanEditViewModel(testLoan);
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.lenderController.text = 'Nouvelle Banque';

      expect(viewModel.lenderName, 'Nouvelle Banque');
      expect(notified, true);

      viewModel.dispose();
    });

    test('should update account id', () {
      final viewModel = LoanEditViewModel(testLoan);
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.setAccountId(5);

      expect(viewModel.selectedAccountId, 5);
      expect(notified, true);

      viewModel.dispose();
    });

    test('should update day of month and clamp between 1 and 31', () {
      final viewModel = LoanEditViewModel(testLoan);

      viewModel.setDayOfMonth(25);
      expect(viewModel.dayOfMonth, 25);

      viewModel.setDayOfMonth(0); // Should clamp to 1
      expect(viewModel.dayOfMonth, 1);

      viewModel.setDayOfMonth(35); // Should clamp to 31
      expect(viewModel.dayOfMonth, 31);

      viewModel.dispose();
    });

    test('should update insurance type', () {
      final viewModel = LoanEditViewModel(testLoan);
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.setInsuranceType(LoanInsuranceType.percentage);

      expect(viewModel.insuranceType, LoanInsuranceType.percentage);
      expect(notified, true);

      viewModel.dispose();
    });

    test('should update insurance calculation mode', () {
      final viewModel = LoanEditViewModel(testLoan);
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.setInsuranceCalculationMode(
        InsuranceCalculationMode.remainingCapital,
      );

      expect(
        viewModel.insuranceCalcMode,
        InsuranceCalculationMode.remainingCapital,
      );
      expect(notified, true);

      viewModel.dispose();
    });

    test('should parse insurance value from controller', () {
      final viewModel = LoanEditViewModel(testLoan);

      viewModel.insuranceValueController.text = '30.5';
      expect(viewModel.insuranceValue, 30.5);

      // Test avec virgule (format français)
      viewModel.insuranceValueController.text = '35,75';
      expect(viewModel.insuranceValue, 35.75);

      // Test avec valeur invalide
      viewModel.insuranceValueController.text = 'invalid';
      expect(viewModel.insuranceValue, 0.0);

      viewModel.dispose();
    });

    test('should calculate monthly insurance payment for fixed type', () {
      final viewModel = LoanEditViewModel(testLoan);

      viewModel.setInsuranceType(LoanInsuranceType.fixed);
      viewModel.insuranceValueController.text = '40';

      expect(viewModel.monthlyInsurancePayment, 40.0);

      viewModel.dispose();
    });

    test('should calculate monthly insurance payment for percentage type', () {
      final viewModel = LoanEditViewModel(testLoan);

      viewModel.setInsuranceType(LoanInsuranceType.percentage);
      viewModel.insuranceValueController.text = '0.36'; // 0.36% par an

      // Calcul: 10000 * 0.36% / 12 = 10000 * 0.0036 / 12 = 3.0
      expect(viewModel.monthlyInsurancePayment, closeTo(3.0, 0.01));

      viewModel.dispose();
    });

    test('should return 0 for monthly insurance payment when type is none', () {
      final viewModel = LoanEditViewModel(testLoan);

      viewModel.setInsuranceType(LoanInsuranceType.none);
      viewModel.insuranceValueController.text = '50';

      expect(viewModel.monthlyInsurancePayment, 0.0);

      viewModel.dispose();
    });

    test('should return 0 for monthly insurance payment when value is 0', () {
      final viewModel = LoanEditViewModel(testLoan);

      viewModel.setInsuranceType(LoanInsuranceType.fixed);
      viewModel.insuranceValueController.text = '0';

      expect(viewModel.monthlyInsurancePayment, 0.0);

      viewModel.dispose();
    });

    test('should validate correctly when all required fields are filled', () {
      final viewModel = LoanEditViewModel(testLoan);

      expect(viewModel.isValid, true);

      viewModel.dispose();
    });

    test('should not validate when name is empty', () {
      final viewModel = LoanEditViewModel(testLoan);

      viewModel.nameController.text = '';

      expect(viewModel.isValid, false);

      viewModel.dispose();
    });

    test('should not validate when lender name is empty', () {
      final viewModel = LoanEditViewModel(testLoan);

      viewModel.lenderController.text = '';

      expect(viewModel.isValid, false);

      viewModel.dispose();
    });

    test('should not validate when account id is invalid', () {
      final viewModel = LoanEditViewModel(testLoan);

      viewModel.setAccountId(-1);

      expect(viewModel.isValid, false);

      viewModel.dispose();
    });

    test('should trim whitespace from name and lender name', () {
      final viewModel = LoanEditViewModel(testLoan);

      viewModel.nameController.text = '  Nom avec espaces  ';
      viewModel.lenderController.text = '  Banque avec espaces  ';

      expect(viewModel.name, 'Nom avec espaces');
      expect(viewModel.lenderName, 'Banque avec espaces');

      viewModel.dispose();
    });

    test('should create updated loan model with modified values', () {
      final viewModel = LoanEditViewModel(testLoan);

      // Modifier les valeurs
      viewModel.nameController.text = 'Nouveau Nom';
      viewModel.lenderController.text = 'Nouvelle Banque';
      viewModel.setAccountId(3);
      viewModel.setDayOfMonth(20);
      viewModel.setInsuranceType(LoanInsuranceType.percentage);
      viewModel.insuranceValueController.text = '0.5';
      viewModel.setInsuranceCalculationMode(
        InsuranceCalculationMode.remainingCapital,
      );

      final updatedModel = viewModel.createUpdatedLoanModel();

      // Vérifier que les champs modifiables sont mis à jour
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

      // Vérifier que les champs en lecture seule restent inchangés
      expect(updatedModel.amount, testLoanModel.amount);
      expect(updatedModel.startDate, testLoanModel.startDate);
      expect(updatedModel.endDate, testLoanModel.endDate);
      expect(updatedModel.duration, testLoanModel.duration);
      expect(updatedModel.interestRate, testLoanModel.interestRate);
      expect(updatedModel.repaymentType, testLoanModel.repaymentType);
      expect(updatedModel.deferredMonths, testLoanModel.deferredMonths);

      viewModel.dispose();
    });

    test('should dispose controllers properly', () {
      final viewModel = LoanEditViewModel(testLoan);

      // Appeler dispose ne devrait pas lever d'exception
      expect(() => viewModel.dispose(), returnsNormally);
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

      const calculationService = LoanCalculationService();
      const breakdownService = LoanPaymentBreakdownService(calculationService);
      final loan = Loan(loanWithDeferred, calculationService, breakdownService);

      final viewModel = LoanEditViewModel(loan);

      expect(viewModel.deferredMonths, 60);

      viewModel.dispose();
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

      const calculationService = LoanCalculationService();
      const breakdownService = LoanPaymentBreakdownService(calculationService);
      final loan = Loan(inFineLoan, calculationService, breakdownService);

      final viewModel = LoanEditViewModel(loan);

      expect(viewModel.repaymentType, LoanRepaymentType.inFine);

      viewModel.dispose();
    });
  });
}
