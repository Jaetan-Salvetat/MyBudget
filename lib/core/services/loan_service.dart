import 'package:mybudget/core/domain/loan.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';
import 'package:mybudget/core/services/loan_payment_breakdown_service.dart';
import 'package:mybudget/models/loan_model.dart';

/// Service singleton pour créer des instances Loan avec leurs dépendances injectées
/// Pattern : Service Locator + Factory
class LoanService {
  static final LoanService _instance = LoanService._internal();
  factory LoanService() => _instance;
  LoanService._internal();

  // Services partagés (singletons)
  final LoanCalculationService _calculationService = const LoanCalculationService();
  late final LoanPaymentBreakdownService _breakdownService =
      LoanPaymentBreakdownService(_calculationService);

  /// Crée une entité Loan à partir d'un LoanModel
  /// Injecte automatiquement les services nécessaires
  Loan createLoan(LoanModel model) {
    return Loan.fromModel(
      model,
      _calculationService,
      _breakdownService,
    );
  }

  /// Crée plusieurs entités Loan à partir d'une liste de LoanModel
  List<Loan> createLoans(List<LoanModel> models) {
    return models.map((model) => createLoan(model)).toList();
  }
}
