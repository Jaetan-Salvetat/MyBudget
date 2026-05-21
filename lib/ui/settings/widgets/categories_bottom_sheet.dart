import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/ui/settings/widgets/category_form_bottom_sheet.dart';

class CategoriesBottomSheet extends ConsumerWidget {
  const CategoriesBottomSheet({super.key});

  static void show({required BuildContext context}) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Gérer les catégories',
      child: const CategoriesBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(categoryProvider)
        .when(
          loading: () => const Center(child: FrostedCircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (categories) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const FrostedDivider(),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return FrostedListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(
                            category.color,
                          ).withAlpha(0x20),
                          child: Icon(
                            category.getIconData(),
                            color: Color(category.color),
                          ),
                        ),
                        title: Text(category.name),
                        trailing: FrostedIconButton(
                          icon: Symbols.delete_rounded,
                          onPressed:
                              () => _showDeleteConfirmation(
                                context,
                                ref,
                                category,
                              ),
                        ),
                        onTap:
                            () => _showEditCategoryForm(context, ref, category),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FrostedFilledButton.icon(
                      onPressed: () => _showAddCategoryForm(context, ref),
                      icon: const Icon(Symbols.add_rounded),
                      label: const Text('Ajouter une catégorie'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  void _showAddCategoryForm(BuildContext context, WidgetRef ref) {
    CategoryFormBottomSheet.show(
      context: context,
      onSubmit: (name, color, icon) async {
        try {
          await ref
              .read(categoryProvider.notifier)
              .addCategory(
                CategoryModel.create(name: name, icon: icon, color: color),
              );
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de l\'ajout: \$e',
            );
          }
        }
      },
    );
  }

  void _showEditCategoryForm(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    CategoryFormBottomSheet.show(
      context: context,
      initial: category,
      onSubmit: (name, color, icon) async {
        try {
          await ref
              .read(categoryProvider.notifier)
              .updateCategory(
                category.copyWith(name: name, color: color, icon: icon),
              );
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(
              context,
              message: 'Erreur lors de la modification: \$e',
            );
          }
        }
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    final linkedExpenses = ref
        .read(expenseProvider.notifier)
        .getExpensesForCategory(category.id);

    if (linkedExpenses.isNotEmpty) {
      FrostedDialog.show(
        context: context,
        title: const Text('Suppression impossible'),
        content: Text(
          '${linkedExpenses.length} dépense${linkedExpenses.length > 1 ? 's sont associées' : ' est associée'} à "${category.name}". Réassignez-les avant de supprimer cette catégorie.',
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
      title: const Text('Supprimer la catégorie'),
      content: Text(
        'Voulez-vous vraiment supprimer la catégorie "${category.name}" ?',
      ),
      actions: [
        FrostedTonalButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () async {
            try {
              await ref
                  .read(categoryProvider.notifier)
                  .deleteCategory(category.id);
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context);
                FrostedSnackbar.show(
                  context,
                  message: 'Erreur lors de la suppression: \$e',
                );
              }
            }
          },
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
