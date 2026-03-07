import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/ui/settings/beneficiary_viewmodel.dart';

class BeneficiariesBottomSheet extends StatelessWidget {
  const BeneficiariesBottomSheet({super.key});

  static void show({required BuildContext context}) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Gérer les bénéficiaires',
      child: const BeneficiariesBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer<BeneficiaryViewModel>(
          builder: (context, beneficiaryVM, child) {
            if (beneficiaryVM.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (beneficiaryVM.beneficiaries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Aucun bénéficiaire',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: beneficiaryVM.beneficiaries.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final beneficiary = beneficiaryVM.beneficiaries[index];
                return FrostedListTile(
                  leading: CircleAvatar(
                    child: Text(
                      beneficiary.name.isNotEmpty
                          ? beneficiary.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(beneficiary.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(
                      context,
                      beneficiaryVM,
                      beneficiary.id,
                      beneficiary.name,
                    ),
                  ),
                );
              },
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FrostedFilledButton.icon(
            onPressed: () => _showAddBeneficiaryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un bénéficiaire'),
          ),
        ),
      ],
    );
  }

  void _showAddBeneficiaryDialog(BuildContext context) {
    final beneficiaryVM = Provider.of<BeneficiaryViewModel>(
      context,
      listen: false,
    );
    final nameController = TextEditingController();
    final errorNotifier = ValueNotifier<String>('');

    FrostedDialog.show(
      context: context,
      title: const Text('Nouveau bénéficiaire'),
      content: ValueListenableBuilder<String>(
        valueListenable: errorNotifier,
        builder: (context, errorMessage, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FrostedTextField(
                controller: nameController,
                labelText: 'Nom',
                hintText: 'Ex: Paul',
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        FrostedTonalButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () async {
            final error = await beneficiaryVM.addBeneficiary(nameController.text);
            if (error == null) {
              if (context.mounted) Navigator.pop(context);
            }
            // L'erreur est affichée dans le ViewModel mais le dialog est stateful,
            // on le gère localement ici via snackbar pour simplifier.
            if (error != null && context.mounted) {
              FrostedSnackbar.show(context, message: error);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    BeneficiaryViewModel vm,
    int id,
    String name,
  ) {
    FrostedDialog.show(
      context: context,
      title: const Text('Supprimer le bénéficiaire'),
      content: Text('Voulez-vous vraiment supprimer "$name" ?'),
      actions: [
        FrostedTonalButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () async {
            Navigator.pop(context);
            final error = await vm.deleteBeneficiary(id);
            if (error != null && context.mounted) {
              FrostedSnackbar.show(context, message: error);
            }
          },
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
