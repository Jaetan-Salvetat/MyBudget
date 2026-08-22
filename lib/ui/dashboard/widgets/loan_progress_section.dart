import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/dashboard/models/loan_progress_summary.dart';

class LoanProgressSection extends StatelessWidget {
  final LoanProgressSummary summary;

  const LoanProgressSection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (!summary.hasLoans) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final pct = (summary.progressPercent * 100).round();
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );
    final monthlyFormatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Emprunts',
          trailing:
              '${summary.activeCount} actif${summary.activeCount > 1 ? 's' : ''}',
        ),
        SolidCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CategoryIcon(
                    icon: Symbols.account_balance_rounded,
                    color: scheme.primary,
                    size: CategoryIconSize.sm,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Capital amorti',
                          style: TextStyle(
                            fontSize: 14,
                            height: 18 / 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatter.format(summary.totalRepaid)} remboursés sur ${formatter.format(summary.totalBorrowed)}',
                          style: TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: AppTextStyles.amount(
                      fontSize: 18,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FrostedLinearProgress(
                value: summary.progressPercent.clamp(0.0, 1.0),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: scheme.onSurface.withValues(alpha: 0.07),
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mensualités du mois',
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      monthlyFormatter.format(summary.monthlyPayments),
                      style: AppTextStyles.amount(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
