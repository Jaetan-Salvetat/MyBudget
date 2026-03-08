import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/ui/settings/widgets/category_form_bottom_sheet.dart';

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
    return SingleChildScrollView(
      child: Column(
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
                      () => _showEditCategoryForm(
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
            onPressed: () => _showAddCategoryForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une catégorie'),
          ),
        ),
      ],
    ),
    );
  }

  void _showAddCategoryForm(BuildContext context) {
    final categoryVM = Provider.of<CategoryViewModel>(context, listen: false);
    CategoryFormBottomSheet.show(
      context: context,
      onSubmit: (name, color, icon) {
        categoryVM.addCategory(
          CategoryModel.create(name: name, icon: icon, color: color),
        );
      },
    );
  }

  void _showEditCategoryForm(
    BuildContext context,
    CategoryViewModel vm,
    CategoryModel category,
  ) {
    CategoryFormBottomSheet.show(
      context: context,
      initial: category,
      onSubmit: (name, color, icon) {
        vm.updateCategory(category.copyWith(name: name, color: color, icon: icon));
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    CategoryViewModel vm,
    CategoryModel category,
  ) {
    final expenseVM = Provider.of<ExpenseViewModel>(context, listen: false);
    final linkedExpenses = expenseVM.getExpensesForCategory(category.id);

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
