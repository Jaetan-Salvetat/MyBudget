import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/loan.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/loans/providers/loan_edit_provider.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';

class LoanEditBottomSheet extends ConsumerStatefulWidget {
  final List<AccountModel> accounts;
  final Function(LoanModel) onSubmit;
  final VoidCallback onCancel;

  const LoanEditBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  static void show({
    required BuildContext context,
    required Loan loan,
    required List<AccountModel> accounts,
    required Function(LoanModel) onSubmit,
    required VoidCallback onCancel,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Modifier l\'emprunt',
      child: ProviderScope(
        // Instance isolée initialisée avec le prêt à éditer
        overrides: [
          loanToEditProvider.overrideWithValue(loan),
        ],
        child: LoanEditBottomSheet(
          accounts: accounts,
          onSubmit: onSubmit,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  ConsumerState<LoanEditBottomSheet> createState() =>
      _LoanEditBottomSheetState();
}

class _LoanEditBottomSheetState extends ConsumerState<LoanEditBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _lenderController;
  late final TextEditingController _insuranceValueController;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(loanEditProvider);

    _nameController = TextEditingController(text: initialState.name);
    _lenderController = TextEditingController(text: initialState.lenderName);
    _insuranceValueController = TextEditingController(
      text: initialState.insuranceValue > 0
          ? initialState.insuranceValue.toString()
          : '',
    );

    _nameController.addListener(
      () => ref.read(loanEditProvider.notifier).setName(_nameController.text),
    );
    _lenderController.addListener(
      () => ref
          .read(loanEditProvider.notifier)
          .setLenderName(_lenderController.text),
    );
    _insuranceValueController.addListener(
      () => ref
          .read(loanEditProvider.notifier)
          .setInsuranceValue(_insuranceValueController.text),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lenderController.dispose();
    _insuranceValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loanEditProvider);
    final notifier = ref.read(loanEditProvider.notifier);

    return Flexible(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),

          // Section 1: Identité (modifiable)
          _buildEditableIdentitySection(context),
          const SizedBox(height: 16),

          // Section 2: Conditions financières (lecture seule)
          _buildReadOnlyFinancialSection(context, state),
          const SizedBox(height: 16),

          // Section 3: Compte et prélèvement (modifiable)
          _buildEditableAccountSection(context, state, notifier),
          const SizedBox(height: 16),

          // Section 4: Assurance (modifiable)
          _buildEditableInsuranceSection(context, state, notifier),
          const SizedBox(height: 24),

          // Boutons d'action
          _buildActionButtons(context, state, notifier),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ========== Section 1: Identité (modifiable) ==========

  Widget _buildEditableIdentitySection(BuildContext context) {
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

  // ========== Section 2: Conditions financières (lecture seule) ==========

  Widget _buildReadOnlyFinancialSection(
    BuildContext context,
    LoanEditState state,
  ) {
    return FrostedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Conditions Financières',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.lock,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
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
                    'Ces paramètres ne peuvent pas être modifiés. Pour les changer, supprimez et recréez le prêt.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildReadOnlyField(
            context,
            'Capital',
            NumberFormat.currency(
              symbol: '€',
              locale: 'fr_FR',
            ).format(state.capital),
          ),
          const Divider(height: 24),

          _buildReadOnlyField(
            context,
            'Date de signature',
            DateFormat('dd/MM/yyyy').format(state.signatureDate),
          ),
          const Divider(height: 24),

          _buildReadOnlyField(context, 'Durée', '${state.duration} mois'),
          const Divider(height: 24),

          _buildReadOnlyField(
            context,
            'Taux d\'intérêt',
            '${state.interestRate} %',
          ),
          const Divider(height: 24),

          _buildReadOnlyField(
            context,
            'Type de remboursement',
            state.repaymentType == LoanRepaymentType.amortizable
                ? 'Amortissable'
                : 'In Fine',
          ),

          if (state.deferredMonths > 0) ...[
            const Divider(height: 24),
            _buildReadOnlyField(
              context,
              'Différé',
              '${state.deferredMonths} mois',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context,
    String label,
    String value,
  ) {
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

  // ========== Section 3: Compte et prélèvement (modifiable) ==========

  Widget _buildEditableAccountSection(
    BuildContext context,
    LoanEditState state,
    LoanEditNotifier notifier,
  ) {
    return FrostedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compte & Prélèvement',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

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

          FrostedTextField(
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
        ],
      ),
    );
  }

  // ========== Section 4: Assurance (modifiable) ==========

  Widget _buildEditableInsuranceSection(
    BuildContext context,
    LoanEditState state,
    LoanEditNotifier notifier,
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

            if (state.insuranceType == LoanInsuranceType.percentage) ...[
              const SizedBox(height: 16),
              Text(
                'Mode de calcul',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ToggleButtons(
                isSelected: [
                  state.insuranceCalcMode ==
                      InsuranceCalculationMode.initialCapital,
                  state.insuranceCalcMode ==
                      InsuranceCalculationMode.remainingCapital,
                ],
                onPressed: (index) {
                  notifier.setInsuranceCalculationMode(
                    InsuranceCalculationMode.values[index],
                  );
                },
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Capital Initial'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Capital Restant'),
                  ),
                ],
              ),
            ],

            if (state.insuranceType == LoanInsuranceType.percentage &&
                state.capital > 0 &&
                state.insuranceValue > 0)
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

  // ========== Boutons d'action ==========

  Widget _buildActionButtons(
    BuildContext context,
    LoanEditState state,
    LoanEditNotifier notifier,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FrostedTextButton(
          onPressed: () {
            widget.onCancel();
            Navigator.pop(context);
          },
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed:
              state.isValid
                  ? () {
                    widget.onSubmit(notifier.createUpdatedLoanModel());
                    Navigator.pop(context);
                  }
                  : null,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
