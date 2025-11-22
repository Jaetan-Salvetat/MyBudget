import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/models/category_model.dart';

class CategoriesBottomSheet extends StatelessWidget {
  const CategoriesBottomSheet({super.key});

  static void show({required BuildContext context}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CategoriesBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return FrostedCard(
          borderRadius: 20,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Gérer les catégories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: Consumer<CategoryViewModel>(
                  builder: (context, categoryVM, child) {
                    if (categoryVM.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: categoryVM.categories.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final category = categoryVM.categories[index];
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
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une catégorie'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final categoryVM = Provider.of<CategoryViewModel>(context, listen: false);
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nouvelle catégorie'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    categoryVM.addCategory(
                      CategoryModel.create(
                        name: nameController.text,
                        icon: Icons.category.codePoint.toString(),
                        color: Colors.blue.value,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    CategoryViewModel vm,
    CategoryModel category,
  ) {
    final nameController = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifier la catégorie'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    vm.updateCategory(
                      category.copyWith(name: nameController.text),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    CategoryViewModel vm,
    CategoryModel category,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer la catégorie'),
            content: Text(
              'Voulez-vous vraiment supprimer la catégorie "${category.name}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  vm.deleteCategory(category.id);
                  Navigator.pop(context);
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
