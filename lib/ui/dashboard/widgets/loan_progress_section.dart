import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/dashboard/models/loan_progress_summary.dart';

class LoanProgressSection extends StatelessWidget {
  static const int _maxVisibleLoans = 3;
  static const double _cardRadius = 16;
  static const EdgeInsets _blockPadding = EdgeInsets.all(14);

  final LoanProgressSummary summary;
  final VoidCallback? onSummaryTap;
  final ValueChanged<int>? onLoanTap;

  const LoanProgressSection({
    super.key,
    required this.summary,
    this.onSummaryTap,
    this.onLoanTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!summary.hasLoans) return const SizedBox.shrink();

    final visible = summary.loans.take(_maxVisibleLoans).toList();
    final hidden = summary.loans.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Emprunts',
          trailing:
              '${summary.activeCount} actif${summary.activeCount > 1 ? 's' : ''}',
        ),
        SolidCard(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TappableBlock(
                onTap: onSummaryTap,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_cardRadius),
                ),
                child: _SummaryBlock(
                  summary: summary,
                  tappable: onSummaryTap != null,
                ),
              ),
              for (final loan in visible) ...[
                const _BlockDivider(),
                _TappableBlock(
                  onTap: onLoanTap == null ? null : () => onLoanTap!(loan.id),
                  borderRadius: hidden == 0 && loan == visible.last
                      ? const BorderRadius.vertical(
                          bottom: Radius.circular(_cardRadius),
                        )
                      : null,
                  child: _LoanRow(loan: loan),
                ),
              ],
              if (hidden > 0) ...[
                const _BlockDivider(),
                _TappableBlock(
                  onTap: onSummaryTap,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(_cardRadius),
                  ),
                  child: _MoreLoansRow(count: hidden),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  final LoanProgressSummary summary;
  final bool tappable;

  const _SummaryBlock({required this.summary, required this.tappable});

  @override
  Widget build(BuildContext context) {
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
              style: AppTextStyles.amount(fontSize: 18, color: scheme.primary),
            ),
            if (tappable) ...[
              const SizedBox(width: 4),
              _Chevron(color: scheme.onSurfaceVariant),
            ],
          ],
        ),
        const SizedBox(height: 12),
        FrostedLinearProgress(value: summary.progressPercent.clamp(0.0, 1.0)),
        const SizedBox(height: 14),
        Row(
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
      ],
    );
  }
}

class _LoanRow extends StatelessWidget {
  final LoanProgressEntry loan;

  const _LoanRow({required this.loan});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 0,
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loan.name,
                style: const TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${formatter.format(loan.remainingCapital)} restants · ${loan.remainingMonths} mois',
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
        const SizedBox(width: 8),
        Text(
          formatter.format(loan.monthlyPayment),
          style: AppTextStyles.amount(fontSize: 14),
        ),
        const SizedBox(width: 4),
        _Chevron(color: scheme.onSurfaceVariant),
      ],
    );
  }
}

class _MoreLoansRow extends StatelessWidget {
  final int count;

  const _MoreLoansRow({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$count autre${count > 1 ? 's' : ''} emprunt${count > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w500,
              color: scheme.primary,
            ),
          ),
        ),
        _Chevron(color: scheme.primary),
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  final Color color;

  const _Chevron({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Symbols.chevron_right_rounded, size: 20, color: color);
  }
}

class _BlockDivider extends StatelessWidget {
  const _BlockDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
    );
  }
}

class _TappableBlock extends StatelessWidget {
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Widget child;

  const _TappableBlock({
    required this.onTap,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding: LoanProgressSection._blockPadding,
      child: child,
    );
    if (onTap == null) return padded;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: padded),
    );
  }
}
