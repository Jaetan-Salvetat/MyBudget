import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/entities/loan_installment.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class LoanScheduleScreen extends StatelessWidget {
  final Loan loan;

  const LoanScheduleScreen({required this.loan, super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final installments = loan.installments;

    return FrostedScaffold(
      appBar: const FrostedTopBar(title: 'Tableau d\'amortissement'),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          topInset + kToolbarHeight + 12,
          16,
          24,
        ),
        itemCount: installments.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeader(context);
          return _buildInstallmentRow(context, installments[index - 1]);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostedCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loan.installments.length} ÉCHÉANCES',
              style: AppTextStyles.mono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacingEm: 0.09,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            _summaryLine(
              context,
              'Capital',
              currency.format(loan.amount),
            ),
            _summaryLine(
              context,
              'Intérêts',
              currency.format(loan.schedule.totalInterest),
            ),
            _summaryLine(
              context,
              'Assurance',
              currency.format(loan.schedule.totalInsurance),
            ),
            if (loan.schedule.totalIndemnity > 0)
              _summaryLine(
                context,
                'Indemnités',
                currency.format(loan.schedule.totalIndemnity),
              ),
            if (loan.fees > 0)
              _summaryLine(context, 'Frais', currency.format(loan.fees)),
            _summaryLine(
              context,
              'Coût total',
              currency.format(loan.totalCost),
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(
    BuildContext context,
    String label,
    String value, {
    bool emphasized = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              color: emphasized ? scheme.primary : scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentRow(
    BuildContext context,
    LoanInstallment installment,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final dateFormat = DateFormat('MM/yyyy');
    final isSettled = !installment.date.isAfter(loan.asOf);

    return Opacity(
      opacity: isSettled ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FrostedCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#${installment.number}',
                    style: AppTextStyles.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacingEm: 0.06,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(installment.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    currency.format(installment.totalPayment),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _breakdownOf(installment, currency),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                'Restant dû ${currency.format(installment.closingCapital)}',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _breakdownOf(LoanInstallment installment, NumberFormat currency) {
    final parts = <String>[
      'Capital ${currency.format(installment.principal)}',
      'Intérêts ${currency.format(installment.interest)}',
    ];

    if (installment.insurance > 0) {
      parts.add('Assurance ${currency.format(installment.insurance)}');
    }
    if (installment.earlyPrincipal > 0) {
      parts.add('Anticipé ${currency.format(installment.earlyPrincipal)}');
    }
    if (installment.indemnity > 0) {
      parts.add('IRA ${currency.format(installment.indemnity)}');
    }

    return parts.join(' · ');
  }
}
