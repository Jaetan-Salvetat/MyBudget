import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';
import 'package:mybudget/core/services/loan_payment_breakdown_service.dart';
import 'package:mybudget/models/loan_model.dart';

class LoanService {
  static final LoanService _instance = LoanService._internal();
  factory LoanService() => _instance;
  LoanService._internal();

  final LoanCalculationService _calculationService = const LoanCalculationService();
  late final LoanPaymentBreakdownService _breakdownService =
      LoanPaymentBreakdownService(_calculationService);

  Loan createLoan(LoanModel model) {
    return Loan.fromModel(
      model,
      _calculationService,
      _breakdownService,
    );
  }

  List<Loan> createLoans(List<LoanModel> models) {
    return models.map((model) => createLoan(model)).toList();
  }
}
