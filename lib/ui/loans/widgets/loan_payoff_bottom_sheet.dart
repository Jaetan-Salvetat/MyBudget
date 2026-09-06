import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/loan_event_types.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/formatting/date_formatter.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/values/early_repayment_quote.dart';
import 'package:mybudget/core/values/loan.dart';
import 'package:mybudget/data/model/loan_event_model.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';
import 'package:mybudget/ui/loans/providers/loan_payoff_provider.dart';

class LoanPayoffBottomSheet extends ConsumerStatefulWidget {
  const LoanPayoffBottomSheet({
    required this.loan,
    required this.onSubmit,
    super.key,
  });
  final Loan loan;
  final void Function(LoanEventModel) onSubmit;

  static void show({
    required BuildContext context,
    required Loan loan,
    required void Function(LoanEventModel) onSubmit,
  }) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: 'Remboursement anticipé',
        child: LoanPayoffBottomSheet(loan: loan, onSubmit: onSubmit),
      ),
    );
  }

  @override
  ConsumerState<LoanPayoffBottomSheet> createState() =>
      _LoanPayoffBottomSheetState();
}

class _LoanPayoffBottomSheetState extends ConsumerState<LoanPayoffBottomSheet> {
  final _amountController = TextEditingController();
  final _dateFormat = DateFormatter.numericDate;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(
      () => ref
          .read(loanPayoffProvider(widget.loan).notifier)
          .setAmount(_amountController.text),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loanPayoffProvider(widget.loan));
    final notifier = ref.read(loanPayoffProvider(widget.loan).notifier);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: [state.isTotal, !state.isTotal],
          onPressed: (index) => notifier.setType(
            index == 0
                ? LoanEventType.earlyRepaymentTotal
                : LoanEventType.earlyRepaymentPartial,
          ),
          borderRadius: BorderRadius.circular(FrostedRadius.md),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('Solder le prêt'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('Versement partiel'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FrostedPickerField(
          icon: Symbols.event_rounded,
          label: 'Date du remboursement',
          text: _dateFormat.format(state.date),
          onTap: () async {
            final picked = await DateSelector.showFullDatePicker(
              context: context,
              initialDate: state.date,
            );
            if (picked != null) notifier.setDate(picked);
          },
        ),
        if (!state.isTotal) ...[
          const SizedBox(height: 12),
          FrostedTextField(
            label: 'Montant remboursé',
            hintText: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            leadingIcon: Symbols.payments_rounded,
            controller: _amountController,
          ),
          const SizedBox(height: 12),
          ToggleButtons(
            isSelected: [
              state.reamortizationMode == ReamortizationMode.reduceDuration,
              state.reamortizationMode == ReamortizationMode.reducePayment,
            ],
            onPressed: (index) => notifier.setReamortizationMode(
              ReamortizationMode.values[index],
            ),
            borderRadius: BorderRadius.circular(FrostedRadius.md),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Text('Réduire la durée'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Text('Réduire la mensualité'),
              ),
            ],
          ),
        ],
        if (state.loan.regime == CreditRegime.mortgage) ...[
          const SizedBox(height: 12),
          FrostedDropdown<EarlyRepaymentExemption>(
            value: state.exemption,
            hintText: 'Motif d\'exonération',
            items: EarlyRepaymentExemption.values
                .map(
                  (exemption) => FrostedDropdownItem(
                    value: exemption,
                    label: exemption.label,
                  ),
                )
                .toList(),
            onChanged: notifier.setExemption,
          ),
        ],
        const SizedBox(height: 16),
        _buildQuoteCard(context, state.quote),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FrostedButton.outlined(
                label: 'Annuler',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FrostedButton.filled(
                label: 'Confirmer',
                onPressed: state.isValid
                    ? () {
                        Navigator.of(context).pop();
                        widget.onSubmit(state.toEventModel());
                      }
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildQuoteCard(BuildContext context, EarlyRepaymentQuote? quote) {
    final scheme = Theme.of(context).colorScheme;

    if (quote == null) {
      return _hint(context, _unavailableQuoteReason(context));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostedCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(
                context,
                'Échéance de règlement',
                _dateFormat.format(quote.settlementDate),
              ),
              _divider(),
              _row(
                context,
                'Mensualité du mois',
                MoneyFormatter.format(quote.settlementPayment),
              ),
              _divider(),
              _row(
                context,
                'Capital remboursé',
                MoneyFormatter.format(quote.repaidCapital),
              ),
              _divider(),
              _row(
                context,
                'Indemnité (IRA)',
                MoneyFormatter.format(quote.indemnity),
              ),
              _divider(),
              _row(
                context,
                'Total à payer',
                MoneyFormatter.format(quote.totalDue),
                emphasized: true,
              ),
              _divider(),
              _row(
                context,
                'Économie réalisée',
                MoneyFormatter.format(quote.costSaved),
              ),
              _divider(),
              _row(
                context,
                quote.clearsTheLoan ? 'Mois évités' : 'Mois gagnés',
                '${quote.monthsSaved}',
              ),
              if (!quote.clearsTheLoan) ...[
                _divider(),
                _row(
                  context,
                  'Nouvelle mensualité',
                  MoneyFormatter.format(quote.newMonthlyPayment),
                ),
                _divider(),
                _row(
                  context,
                  'Nouvelle date de fin',
                  quote.newEndDate == null
                      ? '—'
                      : _dateFormat.format(quote.newEndDate!),
                ),
              ],
            ],
          ),
        ),
        if (quote.isBelowBankMinimum) ...[
          const SizedBox(height: 12),
          _hint(
            context,
            'Sous les 10 % du capital emprunté, la banque peut refuser le versement.',
            color: scheme.error,
          ),
        ],
      ],
    );
  }

  String _unavailableQuoteReason(BuildContext context) {
    final state = ref.read(loanPayoffProvider(widget.loan));

    if (!state.isTotal && state.amount <= 0) {
      return 'Renseignez un montant à rembourser pour estimer le solde.';
    }
    return 'Aucune échéance à solder à cette date : le prêt est déjà remboursé '
        'ou sa dernière échéance est antérieure.';
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: FrostedSpacing.sp3),
    child: FrostedDivider(),
  );

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasized = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: emphasized ? scheme.primary : scheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _hint(BuildContext context, String message, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    final tone = color ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Symbols.info_rounded, size: 18, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 12, color: tone)),
          ),
        ],
      ),
    );
  }
}
