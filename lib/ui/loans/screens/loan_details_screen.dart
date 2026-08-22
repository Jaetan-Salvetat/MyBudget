import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/loans/widgets/loan_detail_hero.dart';
import 'package:mybudget/ui/loans/widgets/loan_detail_info_card.dart';
import 'package:mybudget/ui/loans/widgets/loan_detail_kpi_card.dart';
import 'package:mybudget/ui/loans/widgets/loan_detail_row.dart';
import 'package:mybudget/ui/loans/screens/loan_schedule_screen.dart';
import 'package:mybudget/ui/loans/widgets/loan_early_repayments_card.dart';
import 'package:mybudget/ui/loans/screens/loan_edit_screen.dart';
import 'package:mybudget/ui/loans/widgets/loan_payoff_bottom_sheet.dart';

class LoanDetailsScreen extends ConsumerStatefulWidget {
  final Loan loan;

  const LoanDetailsScreen({required this.loan, super.key});

  @override
  ConsumerState<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends ConsumerState<LoanDetailsScreen> {
  late Loan loan;

  final _formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  final _compactFormatter = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );
  final _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    loan = widget.loan;
  }

  @override
  Widget build(BuildContext context) {
    final loans = ref.watch(loanProvider).value ?? [];
    final accounts = ref.watch(accountProvider).value ?? [];

    final exists = loans.any((l) => l.id == loan.id);
    if (!exists) {
      return const FrostedScaffold(
        body: Center(child: FrostedCircularProgress()),
      );
    }

    final updatedLoan = loans.firstWhere((l) => l.id == loan.id);
    final account = accounts.firstWhere(
      (a) => a.id == updatedLoan.accountId,
      orElse: () => AccountModel.create(name: 'Compte inconnu', bank: ''),
    );

    return FrostedScaffold(
      appBar: const FrostedTopBar(title: 'Détail du prêt'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LoanDetailHero(loan: updatedLoan),
            _buildKpiCard(updatedLoan),
            LoanDetailInfoCard(
              title: 'Détails du prêt',
              rows: _buildLoanRows(updatedLoan, account),
            ),
            LoanDetailInfoCard(
              title: 'Assurance',
              rows: _buildInsuranceRows(updatedLoan),
            ),
            if (updatedLoan.hasEarlyRepayment)
              LoanEarlyRepaymentsCard(
                loan: updatedLoan,
                events: ref
                    .read(loanProvider.notifier)
                    .eventsOf(updatedLoan.id),
                onDelete: (event) => ref
                    .read(loanProvider.notifier)
                    .deleteEvent(event),
              ),
            if (updatedLoan.notes != null && updatedLoan.notes!.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildNotesCard(context, updatedLoan.notes!),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(context, updatedLoan, accounts),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Loan loan,
    List<AccountModel> accounts,
  ) {
    return Column(
      children: [
        if (!loan.isCompleted) ...[
          FrostedButton.filled(
            label: 'Remboursement anticipé',
            icon: Symbols.savings_rounded,
            expanded: true,
            onPressed: () => _showPayoffBottomSheet(context, loan),
          ),
          const SizedBox(height: 10),
        ],
        FrostedButton.tonal(
          label: 'Tableau d\'amortissement',
          icon: Symbols.table_rows_rounded,
          expanded: true,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LoanScheduleScreen(loan: loan),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildEditAndDeleteRow(context, loan, accounts),
      ],
    );
  }

  Widget _buildEditAndDeleteRow(
    BuildContext context,
    Loan loan,
    List<AccountModel> accounts,
  ) {
    return Row(
      children: [
        Expanded(
          child: FrostedButton.text(
            label: 'Modifier',
            icon: Symbols.edit_rounded,
            onPressed: () => _openLoanEditScreen(context, loan, accounts),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FrostedButton.text(
            label: 'Supprimer',
            icon: Symbols.delete_rounded,
            destructive: true,
            onPressed: () => _showDeleteConfirmation(context, loan),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(Loan loan) {
    final durationLabel = loan.duration > 0
        ? '${loan.duration}'
        : '${_monthsBetween(loan.startDate, loan.endDate)}';
    return LoanDetailKpiCard(
      leftLabel: 'Capital restant',
      leftValue: _compactFormatter.format(loan.remainingCapital),
      rightLabel: 'Mois restants',
      rightValue: '${loan.remainingMonths}',
      rightHint: 'sur $durationLabel',
    );
  }

  List<LoanDetailRow> _buildLoanRows(Loan loan, AccountModel account) {
    final rows = <LoanDetailRow>[
      LoanDetailRow(
        label: 'Montant emprunté',
        value: _compactFormatter.format(loan.amount),
      ),
      LoanDetailRow(
        label: 'Taux d\'intérêt',
        value: '${loan.interestRate.toStringAsFixed(2).replaceAll('.', ',')} %',
      ),
      LoanDetailRow(
        label: 'Durée',
        value: loan.hasEarlyRepayment
            ? '${loan.installments.length} mois (au lieu de ${_durationMonths(loan)})'
            : '${_durationMonths(loan)} mois',
      ),
      LoanDetailRow(
        label: 'Type',
        value: loan.repaymentType.label,
        icon: Symbols.trending_down_rounded,
      ),
      if (loan.deferredMonths > 0) ...[
        LoanDetailRow(
          label: 'Mois de différé',
          value: '${loan.deferredMonths}',
        ),
        LoanDetailRow(
          label: 'Type de différé',
          value: loan.deferralType.label,
        ),
      ],
      LoanDetailRow(
        label: 'Date de début',
        value: _dateFormatter.format(loan.startDate),
      ),
      LoanDetailRow(
        label: 'Date de fin',
        value: _dateFormatter.format(loan.endDate),
      ),
      LoanDetailRow(
        label: 'Jour de prélèvement',
        value: 'Le ${loan.dayOfMonth}',
      ),
      if (loan.fees > 0)
        LoanDetailRow(
          label: 'Frais de dossier',
          value: _formatter.format(loan.fees),
        ),
      LoanDetailRow(
        label: 'Coût total',
        value: _formatter.format(loan.totalCost),
      ),
      LoanDetailRow(label: 'Type de prêt', value: loan.purpose.label),
      if (!loan.hasIndemnityClause)
        const LoanDetailRow(
          label: 'Indemnité anticipée',
          value: 'Non prévue au contrat',
        ),
      LoanDetailRow(
        label: 'TAEG',
        value:
            '${loan.annualPercentageRate.toStringAsFixed(2).replaceAll('.', ',')} %',
        icon: Symbols.percent_rounded,
      ),
      LoanDetailRow(
        label: 'Compte',
        value: account.bank.isEmpty
            ? account.name
            : '${account.name} · ${account.bank}',
        showDivider: false,
      ),
    ];
    return rows;
  }

  List<LoanDetailRow> _buildInsuranceRows(Loan loan) {
    if (loan.insuranceType == LoanInsuranceType.none) {
      return const [
        LoanDetailRow(label: 'Type', value: 'Aucune', showDivider: false),
      ];
    }

    final amountLabel = loan.insuranceType == LoanInsuranceType.fixed
        ? '${_formatter.format(loan.insuranceValue)} / mois'
        : '${loan.insuranceValue.toStringAsFixed(2).replaceAll('.', ',')} %';

    return [
      LoanDetailRow(label: 'Type', value: loan.insuranceType.label),
      LoanDetailRow(label: 'Montant', value: amountLabel),
      LoanDetailRow(
        label: 'Mode de calcul',
        value: loan.insuranceCalculationMode.label,
        showDivider: false,
      ),
    ];
  }

  Widget _buildNotesCard(BuildContext context, String notes) {
    final scheme = Theme.of(context).colorScheme;
    return FrostedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.note_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'NOTES',
                style: AppTextStyles.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacingEm: 0.09,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  int _durationMonths(Loan loan) {
    return loan.duration > 0
        ? loan.duration
        : _monthsBetween(loan.startDate, loan.endDate);
  }

  int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month;
  }

  Future<void> _openLoanEditScreen(
    BuildContext context,
    Loan loan,
    List<AccountModel> accounts,
  ) async {
    final updatedLoanModel = await LoanEditScreen.push(
      context: context,
      loan: loan,
      accounts: accounts,
    );
    if (updatedLoanModel == null) return;

    try {
      await ref.read(loanProvider.notifier).updateLoan(updatedLoanModel);
      if (context.mounted) {
        FrostedSnackbar.show(context, message: 'Emprunt mis à jour avec succès');
      }
    } catch (e) {
      if (context.mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de la modification: $e',
        );
      }
    }
  }

  void _showPayoffBottomSheet(BuildContext context, Loan loan) {
    LoanPayoffBottomSheet.show(
      context: context,
      loan: loan,
      onSubmit: (event) async {
        try {
          await ref.read(loanProvider.notifier).addEvent(event);
          if (context.mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Remboursement anticipé enregistré',
            );
          }
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de l\'enregistrement: $e',
            );
          }
        }
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Loan loan) {
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Confirmer la suppression',
        body: const Text(
          'Êtes-vous sûr de vouloir supprimer cet emprunt ? Cette action est irréversible.',
        ),
        actions: [
          FrostedButton.text(
            label: 'Annuler',
            onPressed: () => Navigator.pop(context),
          ),
          FrostedButton.text(
            label: 'Supprimer',
            destructive: true,
            onPressed: () async {
              try {
                await ref.read(loanProvider.notifier).deleteLoan(loan.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  FrostedSnackbar.show(
                    context,
                    message: 'Erreur lors de la suppression: $e',
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
