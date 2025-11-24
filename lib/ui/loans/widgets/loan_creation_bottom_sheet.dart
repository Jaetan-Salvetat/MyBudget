import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/loans/viewmodels/loan_creation_viewmodel.dart';
import 'package:provider/provider.dart';

class LoanCreationBottomSheet extends StatelessWidget {
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
      child: ChangeNotifierProvider(
        create: (_) => LoanCreationViewModel(),
        child: LoanCreationBottomSheet(
          accounts: accounts,
          onSubmit: onSubmit,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanCreationViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: _buildStepperIndicator(context, viewModel),
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
                      key: ValueKey(viewModel.currentStep),
                      child: _buildCurrentStep(context, viewModel),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildBottomArea(context, viewModel),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepperIndicator(
    BuildContext context,
    LoanCreationViewModel viewModel,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(viewModel.totalSteps, (index) {
        final isActive = index <= viewModel.currentStep;
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
    LoanCreationViewModel viewModel,
  ) {
    switch (viewModel.currentStep) {
      case 0:
        return Column(
          children: [
            _buildIdentitySection(context, viewModel),
            const SizedBox(height: 16),
            _buildCapitalSection(context, viewModel),
          ],
        );
      case 1:
        return _buildConditionsSection(context, viewModel);
      case 2:
        return _buildInsuranceSection(context, viewModel);
      case 3:
        return _buildReviewSection(context, viewModel);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdentitySection(
    BuildContext context,
    LoanCreationViewModel viewModel,
  ) {
    return Column(
      children: [
        FrostedTextField(
          labelText: 'Nom du prêt',
          hintText: 'Ex: Prêt Immo Résidence',
          prefixIcon: const Icon(Icons.description),
          controller: viewModel.nameController,
        ),
        const SizedBox(height: 12),
        FrostedTextField(
          labelText: 'Prêteur (Banque)',
          hintText: 'Ex: Banque Populaire',
          prefixIcon: const Icon(Icons.account_balance),
          controller: viewModel.lenderController,
        ),
      ],
    );
  }

  Widget _buildCapitalSection(
    BuildContext context,
    LoanCreationViewModel viewModel,
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
            controller: viewModel.amountController,
          ),
          const SizedBox(height: 12),
          FrostedDropdown<int>(
            value:
                viewModel.selectedAccountId != -1
                    ? viewModel.selectedAccountId
                    : null,
            hint: 'Compte de prélèvement',
            items:
                accounts.map((acc) {
                  return DropdownMenuItem(value: acc.id, child: Text(acc.name));
                }).toList(),
            onChanged: (val) {
              if (val != null) viewModel.setAccountId(val);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FrostedTextField(
                  labelText: 'Début',
                  readOnly: true,
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy').format(viewModel.startDate),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: viewModel.startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2050),
                    );
                    if (date != null) viewModel.setStartDate(date);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FrostedTextField(
                  labelText: 'Jour',
                  hintText: '1-31',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.event),
                  onChanged:
                      (val) => viewModel.setDayOfMonth(int.tryParse(val) ?? 1),
                  controller: TextEditingController(
                      text: viewModel.dayOfMonth.toString(),
                    )
                    ..selection = TextSelection.collapsed(
                      offset: viewModel.dayOfMonth.toString().length,
                    ),
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
    LoanCreationViewModel viewModel,
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
                  controller: viewModel.durationController,
                ),
              ),
              const SizedBox(width: 8),
              ToggleButtons(
                isSelected: [
                  viewModel.durationUnit == DurationUnit.years,
                  viewModel.durationUnit == DurationUnit.months,
                ],
                onPressed: (index) {
                  viewModel.setDurationUnit(
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
            controller: viewModel.rateController,
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceSection(
    BuildContext context,
    LoanCreationViewModel viewModel,
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
                  viewModel.insuranceType == LoanInsuranceType.fixed,
                  viewModel.insuranceType == LoanInsuranceType.percentage,
                  viewModel.insuranceType == LoanInsuranceType.none,
                ],
                onPressed: (index) {
                  viewModel.setInsuranceType(LoanInsuranceType.values[index]);
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
          if (viewModel.insuranceType != LoanInsuranceType.none) ...[
            const SizedBox(height: 12),
            FrostedTextField(
              labelText:
                  viewModel.insuranceType == LoanInsuranceType.fixed
                      ? 'Montant mensuel'
                      : 'Taux annuel',
              hintText:
                  viewModel.insuranceType == LoanInsuranceType.fixed
                      ? '35.00'
                      : '0.36',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              controller: viewModel.insuranceValueController,
            ),
            if (viewModel.insuranceType == LoanInsuranceType.percentage &&
                viewModel.amount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4),
                child: Text(
                  'Soit ${NumberFormat.currency(symbol: '€', locale: 'fr_FR').format(viewModel.monthlyInsurancePayment)} / mois',
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

  Widget _buildReviewSection(
    BuildContext context,
    LoanCreationViewModel viewModel,
  ) {
    final accountName =
        accounts
            .firstWhere(
              (a) => a.id == viewModel.selectedAccountId,
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
              _buildSummaryRow(context, 'Nom', viewModel.name),
              const Divider(height: 24),
              _buildSummaryRow(context, 'Banque', viewModel.lenderName),
              const Divider(height: 24),
              _buildSummaryRow(
                context,
                'Capital',
                NumberFormat.currency(
                  symbol: '€',
                  locale: 'fr_FR',
                ).format(viewModel.amount),
              ),
              const Divider(height: 24),
              _buildSummaryRow(context, 'Compte', accountName),
              const Divider(height: 24),
              _buildSummaryRow(
                context,
                'Durée',
                '${viewModel.durationValue} ${viewModel.durationUnit == DurationUnit.years ? "Ans" : "Mois"}',
              ),
              const Divider(height: 24),
              _buildSummaryRow(context, 'Taux', '${viewModel.interestRate} %'),
              const Divider(height: 24),
              _buildSummaryRow(
                context,
                'Assurance',
                viewModel.insuranceType == LoanInsuranceType.none
                    ? 'Aucune'
                    : '${viewModel.insuranceValue} ${viewModel.insuranceType == LoanInsuranceType.fixed ? "€" : "%"}',
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
    LoanCreationViewModel viewModel,
  ) {
    final isLastStep = viewModel.currentStep == viewModel.totalSteps - 1;

    final bool showMagicCard =
        viewModel.currentStep == 0
            ? viewModel.totalMonthlyPayment > 0
            : viewModel.amount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMagicCard) ...[
          _buildMagicCard(context, viewModel),
          const SizedBox(height: 16),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (viewModel.currentStep > 0)
              FrostedTextButton(
                onPressed: viewModel.previousStep,
                child: const Text('Précédent'),
              )
            else
              const SizedBox(width: 80),

            if (!isLastStep)
              FrostedFilledButton(
                onPressed: viewModel.canGoNext ? viewModel.nextStep : null,
                child: const Text('Suivant'),
              )
            else
              FrostedFilledButton(
                onPressed:
                    viewModel.isValid
                        ? () {
                          onSubmit(viewModel.createLoanModel());
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

  Widget _buildMagicCard(
    BuildContext context,
    LoanCreationViewModel viewModel,
  ) {
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
            ).format(viewModel.totalMonthlyPayment),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (viewModel.insuranceType != LoanInsuranceType.none)
            Text(
              'dont assurance: ${NumberFormat.currency(symbol: '€', locale: 'fr_FR').format(viewModel.monthlyInsurancePayment)}',
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
