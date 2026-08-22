import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_avatar.dart';

class BeneficiariesBottomSheet extends ConsumerWidget {
  const BeneficiariesBottomSheet({super.key});

  static void show({required BuildContext context}) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: 'Gérer les bénéficiaires',
        child: const BeneficiariesBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(beneficiaryProvider)
        .when(
          loading: () => const Center(child: FrostedCircularProgress()),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: beneficiaries.length,
                      separatorBuilder: (context, index) =>
                          const FrostedDivider(),
                      itemBuilder: (context, index) {
                        final beneficiary = beneficiaries[index];
                        return FrostedListTile(
                          title: beneficiary.name,
                          leading: BeneficiaryAvatar(
                            name: beneficiary.name,
                            initials: beneficiary.initials,
                            avatarColor: beneficiary.color,
                          ),
                          trailing: FrostedIconButton.standard(
                            icon: Symbols.delete_rounded,
                            onPressed: () => _showDeleteConfirmation(
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
                    child: FrostedButton.filled(
                      label: 'Ajouter un bénéficiaire',
                      icon: Symbols.add_rounded,
                      onPressed: () => _showAddBeneficiaryDialog(context, ref),
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

    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Nouveau bénéficiaire',
        body: ValueListenableBuilder<String>(
          valueListenable: errorNotifier,
          builder: (context, errorMessage, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FrostedTextField(
                  controller: nameController,
                  label: 'Nom',
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
          FrostedButton.tonal(
            label: 'Annuler',
            onPressed: () => Navigator.pop(context),
          ),
          FrostedButton.filled(
            label: 'Ajouter',
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
          ),
        ],
      ),
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
      showFrostedDialog<void>(
        context: context,
        builder: (_) => FrostedDialog(
          title: 'Suppression impossible',
          body: Text(
            '$usageCount transaction${usageCount > 1 ? 's sont associées' : ' est associée'} à "$name". Réassignez-les avant de supprimer ce bénéficiaire.',
          ),
          actions: [
            FrostedButton.filled(
              label: 'Compris',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Supprimer le bénéficiaire',
        body: Text('Voulez-vous vraiment supprimer "$name" ?'),
        actions: [
          FrostedButton.tonal(
            label: 'Annuler',
            onPressed: () => Navigator.pop(context),
          ),
          FrostedButton.filled(
            label: 'Supprimer',
            onPressed: () async {
              Navigator.pop(context);
              final error = await ref
                  .read(beneficiaryProvider.notifier)
                  .deleteBeneficiary(id);
              if (error != null && context.mounted) {
                FrostedSnackbar.show(context, message: error);
              }
            },
          ),
        ],
      ),
    );
  }
}
