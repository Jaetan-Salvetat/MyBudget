import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/domain/entities/category.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/category_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/dialog_bottom_sheet.dart';

class CategoriesBottomSheet extends StatelessWidget {
  const CategoriesBottomSheet({super.key});

  static Future<void> show({
    required BuildContext context,
  }) {
    return AppModalBottomSheet.show(
      context: context,
      title: 'Gérer les catégories',
      content: const CategoriesBottomSheet(),
      actions: const [],
      isScrollable: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    
    return Obx(() {
      final categories = categoryController.categories;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catégories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  CategoryBottomSheet.show(
                    context: context,
                    onSubmit: (name, icon) {
                      final newCategory = CategoryModel.create(
                        name: name,
                        icon: icon,
                      );
                      categoryController.addCategory(newCategory);
                    },
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune catégorie',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryTile(context, category, categoryController);
              },
            ),
        ],
      );
    });
  }
  
  Widget _buildCategoryTile(BuildContext context, Category category, CategoryController categoryController) {
    IconData iconData = Icons.category;
    try {
      iconData = IconData(
        int.parse(category.icon, radix: 16),
        fontFamily: 'MaterialIcons',
      );
    } catch (e) {
      if (category.icon == 'restaurant') {
        iconData = Icons.restaurant;
      } else if (category.icon == 'directions_car') {
        iconData = Icons.directions_car;
      } else if (category.icon == 'home') {
        iconData = Icons.home;
      } else if (category.icon == 'sports_esports') {
        iconData = Icons.sports_esports;
      } else if (category.icon == 'medical_services') {
        iconData = Icons.medical_services;
      } else if (category.icon == 'checkroom') {
        iconData = Icons.checkroom;
      } else if (category.icon == 'more_horiz') {
        iconData = Icons.more_horiz;
      } else if (category.icon == 'shopping_cart') {
        iconData = Icons.shopping_cart;
      } else if (category.icon == 'fitness_center') {
        iconData = Icons.fitness_center;
      } else if (category.icon == 'school') {
        iconData = Icons.school;
      } else if (category.icon == 'movie') {
        iconData = Icons.movie;
      } else if (category.icon == 'flight_takeoff') {
        iconData = Icons.flight_takeoff;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(category.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                CategoryBottomSheet.show(
                  context: context,
                  initialName: category.name,
                  initialIcon: category.icon,
                  onSubmit: (name, icon) {
                    final updatedCategory = CategoryModel()
                      ..id = int.parse(category.id.toString())
                      ..name = name
                      ..icon = icon;
                    categoryController.updateCategory(updatedCategory);
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                DialogBottomSheet.showConfirmation(
                  context: context,
                  title: 'Supprimer la catégorie',
                  message: 'Êtes-vous sûr de vouloir supprimer la catégorie ${category.name} ?',
                  cancelLabel: 'Annuler',
                  confirmLabel: 'Supprimer',
                  isDestructive: true,
                  onConfirm: () {
                    categoryController.deleteCategory(int.parse(category.id.toString()));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
