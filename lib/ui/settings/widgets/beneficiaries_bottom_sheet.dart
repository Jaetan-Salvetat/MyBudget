import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_avatar.dart';

class BeneficiariesBottomSheet extends ConsumerWidget {
  const BeneficiariesBottomSheet({super.key});

  static void show({required BuildContext context}) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Gérer les bénéficiaires',
      child: const BeneficiariesBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(beneficiaryProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (beneficiaries) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (beneficiaries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'Aucun bénéficiaire',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: beneficiaries.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final beneficiary = beneficiaries[index];
                        return FrostedListTile(
                          leading: BeneficiaryAvatar(
                            name: beneficiary.name,
                            initials: beneficiary.initials,
                            avatarColor: beneficiary.color,
                          ),
                          title: Text(beneficiary.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed:
                                () => _showDeleteConfirmation(
                                  context,
                                  ref,
                                  beneficiary.id,
                                  beneficiary.name,
                                ),
                          ),
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FrostedFilledButton.icon(
                      onPressed: () => _showAddBeneficiaryDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un bénéficiaire'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  void _showAddBeneficiaryDialog(BuildContext context, WidgetRef ref) {
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
            final error = await ref
                .read(beneficiaryProvider.notifier)
                .addBeneficiary(nameController.text);
            if (error == null) {
              if (context.mounted) Navigator.pop(context);
            }
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
    WidgetRef ref,
    int id,
    String name,
  ) {
    final usageCount = ref.read(beneficiaryProvider.notifier).countUsages(id);

    if (usageCount > 0) {
      FrostedDialog.show(
        context: context,
        title: const Text('Suppression impossible'),
        content: Text(
          '$usageCount transaction${usageCount > 1 ? 's sont associées' : ' est associée'} à "$name". Réassignez-les avant de supprimer ce bénéficiaire.',
        ),
        actions: [
          FrostedFilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      );
      return;
    }

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
            final error = await ref
                .read(beneficiaryProvider.notifier)
                .deleteBeneficiary(id);
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
