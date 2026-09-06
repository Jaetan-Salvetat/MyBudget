import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';

class LegacyLoanDefaultsMigration {
  const LegacyLoanDefaultsMigration({required this.loans});
  final LoanRepository loans;

  Future<void> run() async {
    if (PreferencesService.isLegacyLoanDefaultsMigrationDone()) return;

    for (final loan in loans.getAll()) {
      if (loan.purposeId.isNotEmpty) continue;

      loan.purposeId = LoanPurpose.other.name;
      loan.deferralTypeId = LoanDeferralType.partial.name;
      loan.hasIndemnityClause = true;
      loans.update(loan);
    }

    await PreferencesService.setLegacyLoanDefaultsMigrationDone();
  }
}
