import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/loans/providers/loan_creation_provider.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';

class LoanCreationBottomSheet extends ConsumerStatefulWidget {
  final List<AccountModel> accounts;
  final Function(LoanModel) onSubmit;
  final VoidCallback onCancel;

  const LoanCreationBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  static void show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required Function(LoanModel) onSubmit,
    required VoidCallback onCancel,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Nouvel Emprunt Bancaire',
      child: ProviderScope(
        overrides: [loanCreationProvider],
        child: LoanCreationBottomSheet(
          accounts: accounts,
          onSubmit: onSubmit,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  ConsumerState<LoanCreationBottomSheet> createState() =>
      _LoanCreationBottomSheetState();
}

class _LoanCreationBottomSheetState
    extends ConsumerState<LoanCreationBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _lenderController;
  late final TextEditingController _amountController;
  late final TextEditingController _durationController;
  late final TextEditingController _rateController;
  late final TextEditingController _insuranceValueController;
  late final TextEditingController _deferredMonthsController;

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

    _nameController.addListener(
      () => ref
          .read(loanCreationProvider.notifier)
          .setName(_nameController.text),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loanCreationProvider);
    final notifier = ref.read(loanCreationProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: _buildStepperIndicator(context, state),
        ),

        Flexible(
          child: ListView(
            shrinkWrap: true,
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
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
            color:
                isActive
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

  Widget _buildIdentitySection(BuildContext context) {
    return Column(
      children: [
        FrostedTextField(
          labelText: 'Nom du prêt',
          hintText: 'Ex: Prêt Immo Résidence',
          prefixIcon: const Icon(Icons.description),
          controller: _nameController,
        ),
        const SizedBox(height: 12),
        FrostedTextField(
          labelText: 'Prêteur (Banque)',
          hintText: 'Ex: Banque Populaire',
          prefixIcon: const Icon(Icons.account_balance),
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
    return FrostedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
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
            labelText: 'Montant emprunté',
            hintText: '200000',
            prefixIcon: const Icon(Icons.euro),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            controller: _amountController,
          ),
          const SizedBox(height: 12),
          FrostedDropdown<int>(
            value:
                state.selectedAccountId != -1 ? state.selectedAccountId : null,
            hint: 'Compte de prélèvement',
            items:
                widget.accounts.map((acc) {
                  return DropdownMenuItem(value: acc.id, child: Text(acc.name));
                }).toList(),
            onChanged: (val) {
              if (val != null) notifier.setAccountId(val);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FrostedTextField(
                  labelText: 'Date de signature',
                  readOnly: true,
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy').format(state.startDate),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: state.startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2050),
                    );
                    if (date != null) notifier.setStartDate(date);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FrostedTextField(
                  labelText: 'Jour de prélèvement',
                  readOnly: true,
                  controller: TextEditingController(
                    text: state.dayOfMonth.toString(),
                  ),
                  prefixIcon: const Icon(Icons.event),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsSection(
    BuildContext context,
    LoanCreationState state,
    LoanCreationNotifier notifier,
  ) {
    return FrostedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
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
            children: [
              Expanded(
                flex: 2,
                child: FrostedTextField(
                  labelText: 'Durée',
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
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                children: const [Text('Ans'), Text('Mois')],
              ),
            ],
          ),
          const SizedBox(height: 12),
          FrostedTextField(
            labelText: 'Taux d\'intérêt (Annuel)',
            hintText: '3.5',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.percent),
            controller: _rateController,
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentTypeSection(
    BuildContext context,
    LoanCreationState state,
    LoanCreationNotifier notifier,
  ) {
    return FrostedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
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
              FrostedIconButton(
                icon: Icons.help_outline,
                iconSize: 20,
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _showRepaymentTypeHelp(context),
                size: 24,
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
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Amortissable'),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('In Fine'),
              ),
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
                  Icons.info_outline,
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
              FrostedIconButton(
                icon: Icons.help_outline,
                iconSize: 20,
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _showDeferredPeriodHelp(context),
                size: 24,
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
              labelText: 'Durée du différé (en mois)',
              hintText: 'Ex: 24',
              keyboardType: TextInputType.number,
              controller: _deferredMonthsController,
              prefixIcon: const Icon(Icons.schedule),
            ),
          ],
        ],
      ),
    );
  }

  void _showRepaymentTypeHelp(BuildContext context) {
    FrostedDialog.show(
      context: context,
      title: const Text('Types de Remboursement'),
      content: SingleChildScrollView(
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
                    Icons.lightbulb_outline,
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
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Compris'),
        ),
      ],
    );
  }

  void _showDeferredPeriodHelp(BuildContext context) {
    FrostedDialog.show(
      context: context,
      title: const Text('Période de Différé'),
      content: SingleChildScrollView(
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
                    Icons.calculate_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Exemple : PTZ de 120 mois avec 60 mois de différé = 5 ans sans payer, puis 5 ans de remboursements',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
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
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Compris'),
        ),
      ],
    );
  }

  Widget _buildInsuranceSection(
    BuildContext context,
    LoanCreationState state,
    LoanCreationNotifier notifier,
  ) {
    return FrostedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
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
              labelText:
                  state.insuranceType == LoanInsuranceType.fixed
                      ? 'Montant mensuel'
                      : 'Taux annuel',
              hintText:
                  state.insuranceType == LoanInsuranceType.fixed
                      ? '35.00'
                      : '0.36',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              controller: _insuranceValueController,
            ),
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
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context, LoanCreationState state) {
    final accountName =
        widget.accounts
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
              _buildSummaryRow(context, 'Nom', state.name),
              const FrostedDivider(height: 24),
              _buildSummaryRow(context, 'Banque', state.lenderName),
              const FrostedDivider(height: 24),
              _buildSummaryRow(
                context,
                'Capital',
                NumberFormat.currency(
                  symbol: '€',
                  locale: 'fr_FR',
                ).format(state.amount),
              ),
              const FrostedDivider(height: 24),
              _buildSummaryRow(context, 'Compte', accountName),
              const FrostedDivider(height: 24),
              _buildSummaryRow(
                context,
                'Durée',
                '${state.durationValue} ${state.durationUnit == DurationUnit.years ? "Ans" : "Mois"}',
              ),
              const FrostedDivider(height: 24),
              _buildSummaryRow(context, 'Taux', '${state.interestRate} %'),
              const FrostedDivider(height: 24),
              _buildSummaryRow(
                context,
                'Assurance',
                state.insuranceType == LoanInsuranceType.none
                    ? 'Aucune'
                    : '${state.insuranceValue} ${state.insuranceType == LoanInsuranceType.fixed ? "€" : "%"}',
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

    final bool showMagicCard =
        state.currentStep == 0
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
              FrostedTextButton(
                onPressed: notifier.previousStep,
                child: const Text('Précédent'),
              )
            else
              const SizedBox(width: 80),

            if (!isLastStep)
              FrostedFilledButton(
                onPressed: state.canGoNext ? notifier.nextStep : null,
                child: const Text('Suivant'),
              )
            else
              FrostedFilledButton(
                onPressed:
                    state.isValid
                        ? () {
                          widget.onSubmit(notifier.createLoanModel());
                          Navigator.pop(context);
                        }
                        : null,
                child: const Text('Terminer'),
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
