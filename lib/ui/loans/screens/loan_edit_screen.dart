import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
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

class LoanEditScreen extends ConsumerStatefulWidget {
  final List<AccountModel> accounts;

  const LoanEditScreen({required this.accounts, super.key});

  static Future<LoanModel?> push({
    required BuildContext context,
    required Loan loan,
    required List<AccountModel> accounts,
  }) {
    return Navigator.push<LoanModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          overrides: [loanToEditProvider.overrideWithValue(loan)],
          child: LoanEditScreen(accounts: accounts),
        ),
      ),
    );
  }

  @override
  ConsumerState<LoanEditScreen> createState() => _LoanEditScreenState();
}

class _LoanEditScreenState extends ConsumerState<LoanEditScreen> {
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

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Modifier l\'emprunt',
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp4,
                16,
                FrostedSpacing.sp4,
              ),
              children: [
                _buildEditableIdentitySection(context),
                const SizedBox(height: 16),

                _buildReadOnlyFinancialSection(context, state),
                const SizedBox(height: 16),

                _buildEditableAccountSection(context, state, notifier),
                const SizedBox(height: 16),

                _buildEditableInsuranceSection(context, state, notifier),
              ],
            ),
          ),
          _buildActionButtons(context, state, notifier),
        ],
      ),
    );
  }

  Widget _buildEditableIdentitySection(BuildContext context) {
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
                Symbols.lock_rounded,
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
                  Symbols.info_rounded,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp3),
            child: FrostedDivider(),
          ),

          _buildReadOnlyField(
            context,
            'Date de signature',
            DateFormat('dd/MM/yyyy').format(state.signatureDate),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp3),
            child: FrostedDivider(),
          ),

          _buildReadOnlyField(context, 'Durée', '${state.duration} mois'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp3),
            child: FrostedDivider(),
          ),

          _buildReadOnlyField(
            context,
            'Taux d\'intérêt',
            '${state.interestRate} %',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp3),
            child: FrostedDivider(),
          ),

          _buildReadOnlyField(
            context,
            'Type de remboursement',
            state.repaymentType == LoanRepaymentType.amortizable
                ? 'Amortissable'
                : 'In Fine',
          ),

          if (state.deferredMonths > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp3),
              child: FrostedDivider(),
            ),
            _buildReadOnlyField(
              context,
              'Différé',
              '${state.deferredMonths} mois',
            ),
          ],

          if (state.immediateFirstPayment) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp3),
              child: FrostedDivider(),
            ),
            _buildReadOnlyField(context, 'Premier paiement', 'Immédiat'),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: FrostedSpacing.sp2),
        Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

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
            value: state.selectedAccountId != -1
                ? state.selectedAccountId
                : null,
            hintText: 'Compte de prélèvement',
            items: widget.accounts.map((acc) {
              return FrostedDropdownItem(value: acc.id, label: acc.name);
            }).toList(),
            onChanged: (val) {
              notifier.setAccountId(val);
            },
          ),
          const SizedBox(height: 12),

          FrostedPickerField(
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
        ],
      ),
    );
  }

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
              label: state.insuranceType == LoanInsuranceType.fixed
                  ? 'Montant mensuel'
                  : 'Taux annuel',
              hintText: state.insuranceType == LoanInsuranceType.fixed
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
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
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

  Widget _buildActionButtons(
    BuildContext context,
    LoanEditState state,
    LoanEditNotifier notifier,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        0,
        FrostedSpacing.sp4,
        MediaQuery.of(context).padding.bottom + FrostedSpacing.sp4,
      ),
      child: FrostedButton.filled(
        label: 'Enregistrer',
        onPressed: state.isValid
            ? () => Navigator.pop(context, notifier.createUpdatedLoanModel())
            : null,
      ),
    );
  }
}
