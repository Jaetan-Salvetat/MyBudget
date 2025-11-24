import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/models/category_model.dart';

class CategoriesBottomSheet extends StatelessWidget {
  const CategoriesBottomSheet({super.key});

  static void show({required BuildContext context}) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Gérer les catégories',
      child: const CategoriesBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer<CategoryViewModel>(
          builder: (context, categoryVM, child) {
            if (categoryVM.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryVM.categories.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final category = categoryVM.categories[index];
                return FrostedListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(category.color).withAlpha(0x20),
                    child: Icon(
                      category.getIconData(),
                      color: Color(category.color),
                    ),
                  ),
                  title: Text(category.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed:
                        () => _showDeleteConfirmation(
                          context,
                          categoryVM,
                          category,
                        ),
                  ),
                  onTap:
                      () => _showEditCategoryDialog(
                        context,
                        categoryVM,
                        category,
                      ),
                );
              },
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FrostedFilledButton.icon(
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une catégorie'),
          ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final categoryVM = Provider.of<CategoryViewModel>(context, listen: false);
    final nameController = TextEditingController();

    FrostedDialog.show(
      context: context,
      title: const Text('Nouvelle catégorie'),
      content: FrostedTextField(controller: nameController, labelText: 'Nom'),
      actions: [
        FrostedTonalButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              categoryVM.addCategory(
                CategoryModel.create(
                  name: nameController.text,
                  icon: Icons.category.codePoint.toString(),
                  color: Colors.blue.toARGB32(),
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    CategoryViewModel vm,
    CategoryModel category,
  ) {
    final nameController = TextEditingController(text: category.name);

    FrostedDialog.show(
      context: context,
      title: const Text('Modifier la catégorie'),
      content: FrostedTextField(controller: nameController, labelText: 'Nom'),
      actions: [
        FrostedTonalButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              vm.updateCategory(category.copyWith(name: nameController.text));
              Navigator.pop(context);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    CategoryViewModel vm,
    CategoryModel category,
  ) {
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
          onPressed: () {
            vm.deleteCategory(category.id);
            Navigator.pop(context);
          },
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
