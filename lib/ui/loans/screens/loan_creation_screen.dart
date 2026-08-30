import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/loans/providers/loan_creation_provider.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';

const double _durationUnitToggleHeight = 50;

class LoanCreationScreen extends ConsumerStatefulWidget {
  final List<AccountModel> accounts;

  const LoanCreationScreen({required this.accounts, super.key});

  static Future<LoanModel?> push({
    required BuildContext context,
    required List<AccountModel> accounts,
  }) {
    return Navigator.push<LoanModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          overrides: [loanCreationProvider],
          child: LoanCreationScreen(accounts: accounts),
        ),
      ),
    );
  }

  @override
  ConsumerState<LoanCreationScreen> createState() => _LoanCreationScreenState();
}

class _LoanCreationScreenState extends ConsumerState<LoanCreationScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _lenderController;
  late final TextEditingController _amountController;
  late final TextEditingController _durationController;
  late final TextEditingController _rateController;
  late final TextEditingController _insuranceValueController;
  late final TextEditingController _deferredMonthsController;
  late final TextEditingController _feesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _lenderController = TextEditingController();
    _amountController = TextEditingController();
    _durationController = TextEditingController();
    _rateController = TextEditingController();
    _insuranceValueController = TextEditingController();
    _deferredMonthsController = TextEditingController();
    _feesController = TextEditingController();

    _nameController.addListener(
      () =>
          ref.read(loanCreationProvider.notifier).setName(_nameController.text),
    );
    _lenderController.addListener(
      () => ref
          .read(loanCreationProvider.notifier)
          .setLenderName(_lenderController.text),
    );
    _amountController.addListener(
      () => ref
          .read(loanCreationProvider.notifier)
          .setAmount(_amountController.text),
    );
    _durationController.addListener(
      () => ref
          .read(loanCreationProvider.notifier)
          .setDurationValue(_durationController.text),
    );
    _rateController.addListener(
      () => ref
          .read(loanCreationProvider.notifier)
          .setInterestRate(_rateController.text),
    );
    _insuranceValueController.addListener(
      () => ref
          .read(loanCreationProvider.notifier)
          .setInsuranceValue(_insuranceValueController.text),
    );
    _feesController.addListener(
      () => ref.read(loanCreationProvider.notifier).setFees(_feesController.text),
    );
    _deferredMonthsController.addListener(
      () => ref
          .read(loanCreationProvider.notifier)
          .setDeferredMonths(_deferredMonthsController.text),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lenderController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    _rateController.dispose();
    _insuranceValueController.dispose();
    _deferredMonthsController.dispose();
    _feesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loanCreationProvider);
    final notifier = ref.read(loanCreationProvider.notifier);

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Nouvel emprunt bancaire',
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              0,
              FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp4,
              0,
              FrostedSpacing.sp4,
            ),
            child: _buildStepperIndicator(context, state),
          ),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(state.currentStep),
                    child: _buildCurrentStep(context, state, notifier),
                  ),
                ),

                const SizedBox(height: 24),

                _buildBottomArea(context, state, notifier),

                SizedBox(
                  height:
                      MediaQuery.of(context).padding.bottom +
                      FrostedSpacing.sp4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperIndicator(BuildContext context, LoanCreationState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(state.totalSteps, (index) {
        final isActive = index <= state.currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 40 : 12,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(
    BuildContext context,
    LoanCreationState state,
    LoanCreationNotifier notifier,
  ) {
    switch (state.currentStep) {
      case 0:
        return Column(
          children: [
            _buildPurposeField(context, state, notifier),
            _buildIdentitySection(context),
            const SizedBox(height: 16),
            _buildCapitalSection(context, state, notifier),
          ],
        );
      case 1:
        return _buildConditionsSection(context, state, notifier);
      case 2:
        return _buildRepaymentTypeSection(context, state, notifier);
      case 3:
        return _buildInsuranceSection(context, state, notifier);
      case 4:
        return _buildReviewSection(context, state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPurposeField(
    BuildContext context,
    LoanCreationState state,
    LoanCreationNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FrostedDropdown<LoanPurpose>(
          value: state.purpose,
          hintText: 'Type de prêt',
          items: LoanPurpose.values
              .map(
                (purpose) =>
                    FrostedDropdownItem(value: purpose, label: purpose.label),
              )
              .toList(),
          onChanged: notifier.setPurpose,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildIdentitySection(BuildContext context) {
    return Column(
      children: [
        FrostedTextField(
          label: 'Nom du prêt',
          hintText: 'Ex: Prêt Immo Résidence',
          leadingIcon: Symbols.description_rounded,
          controller: _nameController,
        ),
        const SizedBox(height: 12),
        FrostedTextField(
          label: 'Prêteur (Banque)',
          hintText: 'Ex: Banque Populaire',
          leadingIcon: Symbols.account_balance_rounded,
          controller: _lenderController,
        ),
      ],
    );
  }

  Widget _buildCapitalSection(
    BuildContext context,
    LoanCreationState state,
    LoanCreationNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capital & Compte',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        FrostedTextField(
          label: 'Montant emprunté',
          hintText: '200000',
          leadingIcon: Symbols.euro_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          controller: _amountController,
        ),
        const SizedBox(height: 12),
        FrostedDropdown<int>(
          value: state.selectedAccountId != -1 ? state.selectedAccountId : null,
          hintText: 'Compte de prélèvement',
          items: widget.accounts.map((acc) {
            return FrostedDropdownItem(value: acc.id, label: acc.name);
          }).toList(),
          onChanged: (val) {
            notifier.setAccountId(val);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FrostedPickerField(
                icon: Symbols.calendar_today_rounded,
                onTap: () async {
                  final date = await showFrostedDatePicker(
                    context: context,
                    initialDate: state.startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2050),
                  );
                  if (date != null) notifier.setStartDate(date);
                },
                label: 'Date de signature',
                text: DateFormat('dd/MM/yyyy').format(state.startDate),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FrostedPickerField(
                icon: Symbols.event_rounded,
                onTap: () async {
                  final selectedDate = await DateSelector.showDayPicker(
                    context: context,
                    initialDate: DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      state.dayOfMonth,
                    ),
                  );
                  if (selectedDate != null) {
                    notifier.setDayOfMonth(selectedDate.day);
                  }
                },
                label: 'Jour de prélèvement',
                text: state.dayOfMonth.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: state.immediateFirstPayment,
          onChanged: (_) => notifier.toggleImmediateFirstPayment(),
          title: const Text('Premier paiement immédiat'),
          subtitle: const Text(
            'Le premier paiement a lieu le mois de signature',
          ),
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildConditionsSection(
    BuildContext context,
    LoanCreationState state,
    LoanCreationNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conditions',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 2,
              child: FrostedTextField(
                label: 'Durée',
                hintText: '20',
                keyboardType: TextInputType.number,
                controller: _durationController,
              ),
            ),
            const SizedBox(width: 8),
            ToggleButtons(
              isSelected: [
                state.durationUnit == DurationUnit.years,
                state.durationUnit == DurationUnit.months,
              ],
              onPressed: (index) {
                notifier.setDurationUnit(
                  index == 0 ? DurationUnit.years : DurationUnit.months,
                );
              },
              borderRadius: BorderRadius.circular(FrostedRadius.md),
              constraints: const BoxConstraints(
                minHeight: _durationUnitToggleHeight,
                minWidth: 48,
              ),
              children: const [Text('Ans'), Text('Mois')],
            ),
          ],
        ),
        const SizedBox(height: 12),
        FrostedTextField(
          label: 'Taux d\'intérêt (Annuel)',
          hintText: '3.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          leadingIcon: Symbols.percent_rounded,
          controller: _rateController,
        ),
        const SizedBox(height: 12),
        FrostedTextField(
          label: 'Frais (dossier, garantie, courtage)',
          hintText: '0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          leadingIcon: Symbols.receipt_long_rounded,
          controller: _feesController,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: notifier.toggleIndemnityClause,
          child: Row(
            children: [
              FrostedCheckbox(
                value: !state.hasIndemnityClause,
                onChanged: (_) => notifier.toggleIndemnityClause(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Le contrat ne prévoit aucune indemnité de remboursement anticipé',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepaymentTypeSection(
    BuildContext context,
    LoanCreationState state,
    LoanCreationNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Type de Remboursement',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            FrostedIconButton.standard(
              icon: Symbols.help_rounded,
              size: FrostedIconButtonSize.small,
              onPressed: () => _showRepaymentTypeHelp(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ToggleButtons(
          isSelected: [
            state.repaymentType == LoanRepaymentType.amortizable,
            state.repaymentType == LoanRepaymentType.inFine,
          ],
          onPressed: (index) {
            notifier.setRepaymentType(LoanRepaymentType.values[index]);
          },
          borderRadius: BorderRadius.circular(8),
          children: const [
            Padding(padding: EdgeInsets.all(12), child: Text('Amortissable')),
            Padding(padding: EdgeInsets.all(12), child: Text('In Fine')),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Symbols.info_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.repaymentType == LoanRepaymentType.amortizable
                      ? 'Vous remboursez capital + intérêts chaque mois (le plus courant)'
                      : 'Vous ne payez que les intérêts chaque mois, le capital est remboursé à la fin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Période de Différé',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            FrostedIconButton.standard(
              icon: Symbols.help_rounded,
              size: FrostedIconButtonSize.small,
              onPressed: () => _showDeferredPeriodHelp(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => notifier.toggleDeferredPeriod(),
          child: Row(
            children: [
              FrostedCheckbox(
                value: state.hasDeferredPeriod,
                onChanged: (_) => notifier.toggleDeferredPeriod(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Ce prêt a une période de différé (ex: PTZ)'),
              ),
            ],
          ),
        ),
        if (state.hasDeferredPeriod) ...[
          const SizedBox(height: 12),
          FrostedTextField(
            label: 'Durée du différé (en mois)',
            hintText: 'Ex: 24',
            keyboardType: TextInputType.number,
            controller: _deferredMonthsController,
            leadingIcon: Symbols.schedule_rounded,
          ),
          const SizedBox(height: 12),
          ToggleButtons(
            isSelected: [
              state.deferralType == LoanDeferralType.partial,
              state.deferralType == LoanDeferralType.total,
            ],
            onPressed: (index) => notifier.setDeferralType(
              index == 0 ? LoanDeferralType.partial : LoanDeferralType.total,
            ),
            borderRadius: BorderRadius.circular(FrostedRadius.md),
            children: const [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Différé partiel'),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Différé total'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHint(context, state.deferralType.description),
        ],
      ],
    );
  }

  void _showRepaymentTypeHelp(BuildContext context) {
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Types de Remboursement',
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Prêt Amortissable',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Type le plus courant (99% des prêts immobiliers)\n'
                '• Vous remboursez capital + intérêts chaque mois\n'
                '• Mensualité constante pendant toute la durée\n'
                '• La part de capital augmente progressivement\n'
                '• La part d\'intérêts diminue progressivement',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Prêt In Fine',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Type rare, réservé aux investissements locatifs\n'
                '• Vous ne payez QUE les intérêts chaque mois\n'
                '• Le capital est remboursé en une seule fois à la fin\n'
                '• Mensualités plus faibles mais coût total plus élevé\n'
                '• Permet de défiscaliser les intérêts',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.lightbulb_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pour un prêt immobilier classique, choisissez "Amortissable"',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FrostedButton.text(
            label: 'Compris',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDeferredPeriodHelp(BuildContext context) {
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Période de Différé',
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Une période de différé vous permet de ne rien payer pendant les premiers mois du prêt.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Exemple : Prêt à Taux Zéro (PTZ)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Vous pouvez avoir 5, 10 ou 15 ans de différé\n'
                '• Pendant cette période, vous ne payez rien du tout\n'
                '• Les remboursements commencent après le différé\n'
                '• La durée totale du prêt inclut le différé',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.calculate_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Exemple : PTZ de 120 mois avec 60 mois de différé = 5 ans sans payer, puis 5 ans de remboursements',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FrostedButton.text(
            label: 'Compris',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceSection(
    BuildContext context,
    LoanCreationState state,
    LoanCreationNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assurance Emprunteur',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return ToggleButtons(
              isSelected: [
                state.insuranceType == LoanInsuranceType.fixed,
                state.insuranceType == LoanInsuranceType.percentage,
                state.insuranceType == LoanInsuranceType.none,
              ],
              onPressed: (index) {
                notifier.setInsuranceType(LoanInsuranceType.values[index]);
              },
              borderRadius: BorderRadius.circular(8),
              constraints: BoxConstraints.expand(
                width: (constraints.maxWidth - 4) / 3,
                height: 40,
              ),
              children: const [
                Text('Fixe (€)'),
                Text('Taux (%)'),
                Text('Aucune'),
              ],
            );
          },
        ),
        if (state.insuranceType != LoanInsuranceType.none) ...[
          const SizedBox(height: 12),
          FrostedTextField(
            label: state.insuranceType == LoanInsuranceType.fixed
                ? 'Montant mensuel'
                : 'Taux annuel',
            hintText: state.insuranceType == LoanInsuranceType.fixed
                ? '35.00'
                : '0.36',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: _insuranceValueController,
          ),
          if (state.insuranceType == LoanInsuranceType.percentage) ...[
            const SizedBox(height: 12),
            ToggleButtons(
              isSelected: [
                state.insuranceCalcMode ==
                    InsuranceCalculationMode.initialCapital,
                state.insuranceCalcMode ==
                    InsuranceCalculationMode.remainingCapital,
              ],
              onPressed: (index) => notifier.setInsuranceCalculationMode(
                InsuranceCalculationMode.values[index],
              ),
              borderRadius: BorderRadius.circular(FrostedRadius.md),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Text('Capital initial'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Text('Capital restant dû'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHint(context, state.insuranceCalcMode.description),
          ],
          if (state.insuranceType == LoanInsuranceType.percentage &&
              state.amount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4),
              child: Text(
                'Soit ${NumberFormat.currency(symbol: '€', locale: 'fr_FR').format(state.monthlyInsurancePayment)} / mois',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildReviewSection(BuildContext context, LoanCreationState state) {
    final accountName = widget.accounts
        .firstWhere(
          (a) => a.id == state.selectedAccountId,
          orElse: () => AccountModel.create(name: 'Inconnu', bank: ''),
        )
        .name;

    return Column(
      children: [
        FrostedCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Récapitulatif',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow(context, 'Type', state.purpose.label),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.sp3,
                ),
                child: FrostedDivider(),
              ),
              _buildSummaryRow(context, 'Nom', state.name),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.sp3,
                ),
                child: FrostedDivider(),
              ),
              _buildSummaryRow(context, 'Banque', state.lenderName),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.sp3,
                ),
                child: FrostedDivider(),
              ),
              _buildSummaryRow(
                context,
                'Capital',
                NumberFormat.currency(
                  symbol: '€',
                  locale: 'fr_FR',
                ).format(state.amount),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.sp3,
                ),
                child: FrostedDivider(),
              ),
              _buildSummaryRow(context, 'Compte', accountName),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.sp3,
                ),
                child: FrostedDivider(),
              ),
              _buildSummaryRow(
                context,
                'Durée',
                '${state.durationValue} ${state.durationUnit == DurationUnit.years ? "Ans" : "Mois"}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.sp3,
                ),
                child: FrostedDivider(),
              ),
              _buildSummaryRow(context, 'Taux', '${state.interestRate} %'),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.sp3,
                ),
                child: FrostedDivider(),
              ),
              _buildSummaryRow(
                context,
                'Assurance',
                state.insuranceType == LoanInsuranceType.none
                    ? 'Aucune'
                    : '${state.insuranceValue} ${state.insuranceType == LoanInsuranceType.fixed ? "€" : "%"}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.sp3,
                ),
                child: FrostedDivider(),
              ),
              _buildSummaryRow(
                context,
                'Mensualité',
                NumberFormat.currency(
                  symbol: '€',
                  locale: 'fr_FR',
                ).format(state.totalMonthlyPayment),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.sp3,
                ),
                child: FrostedDivider(),
              ),
              _buildSummaryRow(
                context,
                'Coût total du crédit',
                NumberFormat.currency(
                  symbol: '€',
                  locale: 'fr_FR',
                ).format(state.totalCost),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.sp3,
                ),
                child: FrostedDivider(),
              ),
              _buildSummaryRow(
                context,
                'TAEG',
                '${state.annualPercentageRate.toStringAsFixed(2).replaceAll('.', ',')} %',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Vérifiez que tout est correct avant de valider.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHint(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.info_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBottomArea(
    BuildContext context,
    LoanCreationState state,
    LoanCreationNotifier notifier,
  ) {
    final isLastStep = state.currentStep == state.totalSteps - 1;

    final bool showMagicCard = state.currentStep == 0
        ? state.totalMonthlyPayment > 0
        : state.amount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMagicCard) ...[
          _buildMagicCard(context, state),
          const SizedBox(height: 16),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (state.currentStep > 0)
              FrostedButton.text(
                label: 'Précédent',
                onPressed: notifier.previousStep,
              )
            else
              const SizedBox(width: 80),

            if (!isLastStep)
              FrostedButton.filled(
                label: 'Suivant',
                onPressed: state.canGoNext ? notifier.nextStep : null,
              )
            else
              FrostedButton.filled(
                label: 'Terminer',
                onPressed: state.isValid
                    ? () =>
                          Navigator.pop(context, notifier.createLoanModel())
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMagicCard(BuildContext context, LoanCreationState state) {
    return FrostedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Mensualité Estimée',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(
              symbol: '€',
              locale: 'fr_FR',
            ).format(state.totalMonthlyPayment),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (state.insuranceType != LoanInsuranceType.none)
            Text(
              'dont assurance: ${NumberFormat.currency(symbol: '€', locale: 'fr_FR').format(state.monthlyInsurancePayment)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }
}
