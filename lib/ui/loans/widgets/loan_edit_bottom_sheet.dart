import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/domain/loan.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/ui/loans/viewmodels/loan_edit_viewmodel.dart';
import 'package:mybudget/ui/common/widgets/frosted_date_selector.dart';
import 'package:provider/provider.dart';

class LoanEditBottomSheet extends StatelessWidget {
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
      child: ChangeNotifierProvider(
        create: (_) => LoanEditViewModel(loan),
        child: LoanEditBottomSheet(
          accounts: accounts,
          onSubmit: onSubmit,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanEditViewModel>(
      builder: (context, viewModel, _) {
        return Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 16),

              // Section 1: Identité (modifiable)
              _buildEditableIdentitySection(context, viewModel),
              const SizedBox(height: 16),

              // Section 2: Conditions financières (lecture seule)
              _buildReadOnlyFinancialSection(context, viewModel),
              const SizedBox(height: 16),

              // Section 3: Compte et prélèvement (modifiable)
              _buildEditableAccountSection(context, viewModel, accounts),
              const SizedBox(height: 16),

              // Section 4: Assurance (modifiable)
              _buildEditableInsuranceSection(context, viewModel),
              const SizedBox(height: 24),

              // Boutons d'action
              _buildActionButtons(context, viewModel),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ========== Section 1: Identité (modifiable) ==========

  Widget _buildEditableIdentitySection(
    BuildContext context,
    LoanEditViewModel viewModel,
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

  // ========== Section 2: Conditions financières (lecture seule) ==========

  Widget _buildReadOnlyFinancialSection(
    BuildContext context,
    LoanEditViewModel viewModel,
  ) {
    return FrostedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec icône lock
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

          // Message d'information
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

          // Champs en lecture seule
          _buildReadOnlyField(
            context,
            'Capital',
            NumberFormat.currency(symbol: '€', locale: 'fr_FR')
                .format(viewModel.capital),
          ),
          const Divider(height: 24),

          _buildReadOnlyField(
            context,
            'Date de signature',
            DateFormat('dd/MM/yyyy').format(viewModel.signatureDate),
          ),
          const Divider(height: 24),

          _buildReadOnlyField(
            context,
            'Durée',
            '${viewModel.duration} mois',
          ),
          const Divider(height: 24),

          _buildReadOnlyField(
            context,
            'Taux d\'intérêt',
            '${viewModel.interestRate} %',
          ),
          const Divider(height: 24),

          _buildReadOnlyField(
            context,
            'Type de remboursement',
            viewModel.repaymentType == LoanRepaymentType.amortizable
                ? 'Amortissable'
                : 'In Fine',
          ),

          // Afficher le différé seulement s'il existe
          if (viewModel.deferredMonths > 0) ...[
            const Divider(height: 24),
            _buildReadOnlyField(
              context,
              'Différé',
              '${viewModel.deferredMonths} mois',
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
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ========== Section 3: Compte et prélèvement (modifiable) ==========

  Widget _buildEditableAccountSection(
    BuildContext context,
    LoanEditViewModel viewModel,
    List<AccountModel> accounts,
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
            value: viewModel.selectedAccountId != -1
                ? viewModel.selectedAccountId
                : null,
            hint: 'Compte de prélèvement',
            items: accounts.map((acc) {
              return DropdownMenuItem(value: acc.id, child: Text(acc.name));
            }).toList(),
            onChanged: (val) {
              if (val != null) viewModel.setAccountId(val);
            },
          ),
          const SizedBox(height: 12),

          FrostedTextField(
            labelText: 'Jour de prélèvement',
            readOnly: true,
            controller: TextEditingController(
              text: viewModel.dayOfMonth.toString(),
            ),
            prefixIcon: const Icon(Icons.event),
            onTap: () async {
              final selectedDate = await FrostedDateSelector.showDayPicker(
                context: context,
                initialDate: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  viewModel.dayOfMonth,
                ),
              );
              if (selectedDate != null) {
                viewModel.setDayOfMonth(selectedDate.day);
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
    LoanEditViewModel viewModel,
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

          // ToggleButtons pour le type d'assurance
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

          // Champ de saisie si assurance active
          if (viewModel.insuranceType != LoanInsuranceType.none) ...[
            const SizedBox(height: 12),
            FrostedTextField(
              labelText: viewModel.insuranceType == LoanInsuranceType.fixed
                  ? 'Montant mensuel'
                  : 'Taux annuel',
              hintText: viewModel.insuranceType == LoanInsuranceType.fixed
                  ? '35.00'
                  : '0.36',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              controller: viewModel.insuranceValueController,
            ),

            // Mode de calcul si assurance en pourcentage
            if (viewModel.insuranceType == LoanInsuranceType.percentage) ...[
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
                  viewModel.insuranceCalcMode ==
                      InsuranceCalculationMode.initialCapital,
                  viewModel.insuranceCalcMode ==
                      InsuranceCalculationMode.remainingCapital,
                ],
                onPressed: (index) {
                  viewModel.setInsuranceCalculationMode(
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

            // Prévisualisation du montant mensuel
            if (viewModel.insuranceType == LoanInsuranceType.percentage &&
                viewModel.capital > 0 &&
                viewModel.insuranceValue > 0)
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

  // ========== Boutons d'action ==========

  Widget _buildActionButtons(
    BuildContext context,
    LoanEditViewModel viewModel,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FrostedTextButton(
          onPressed: () {
            onCancel();
            Navigator.pop(context);
          },
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: viewModel.isValid
              ? () {
                  onSubmit(viewModel.createUpdatedLoanModel());
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
