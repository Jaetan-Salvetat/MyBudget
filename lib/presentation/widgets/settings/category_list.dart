import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/domain/entities/category.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/presentation/widgets/common/app_text_field.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      body: Obx(() {
        final categories = categoryController.categories;

        return categories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryTile(category: category);
                },
              );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddEditCategoryDialog(
              onSubmit: (name, icon) {
                final newCategory = CategoryModel.create(
                  name: name,
                  icon: icon,
                );
                categoryController.addCategory(newCategory);
                Navigator.of(context).pop();
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final Category category;

  const CategoryTile({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.find<CategoryController>();
    
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
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(iconData),
        title: Text(category.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddEditCategoryDialog(
                    initialName: category.name,
                    initialIcon: category.icon,
                    onSubmit: (name, icon) {
                      final updatedCategory = (category as CategoryModel).copyWith(
                        name: name,
                        icon: icon,
                      );
                      categoryController.updateCategory(updatedCategory);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete, 
                color: Theme.of(context).colorScheme.error
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer la catégorie'),
                    content: Text(
                      'Êtes-vous sûr de vouloir supprimer la catégorie ${category.name} ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () {
                          categoryController.deleteCategory(category.id);
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AddEditCategoryDialog extends StatefulWidget {
  final String? initialName;
  final String? initialIcon;
  final Function(String, String) onSubmit;

  const AddEditCategoryDialog({
    this.initialName,
    this.initialIcon,
    required this.onSubmit,
    super.key,
  });

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final nameController = TextEditingController();
  String selectedIcon = 'category';

  final List<Map<String, dynamic>> availableIcons = [
    {'name': 'category', 'icon': Icons.category, 'label': 'Défaut'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Restaurant'},
    {'name': 'directions_car', 'icon': Icons.directions_car, 'label': 'Transport'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Maison'},
    {'name': 'sports_esports', 'icon': Icons.sports_esports, 'label': 'Jeux'},
    {
      'name': 'medical_services',
      'icon': Icons.medical_services,
      'label': 'Santé',
    },
    {'name': 'fitness_center', 'icon': Icons.fitness_center, 'label': 'Sport'},
    {'name': 'flight_takeoff', 'icon': Icons.flight_takeoff, 'label': 'Voyage'},
    {'name': 'checkroom', 'icon': Icons.checkroom, 'label': 'Vêtements'},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart, 'label': 'Shopping'},
    {'name': 'school', 'icon': Icons.school, 'label': 'Éducation'},
    {'name': 'movie', 'icon': Icons.movie, 'label': 'Divertissement'},
    {'name': 'more_horiz', 'icon': Icons.more_horiz, 'label': 'Autre'},
  ];

  @override
  void initState() {
    super.initState();

    if (widget.initialName != null) {
      nameController.text = widget.initialName!;
    }

    if (widget.initialIcon != null) {
      selectedIcon = widget.initialIcon!;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialName == null
            ? 'Ajouter une catégorie'
            : 'Modifier la catégorie',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: nameController,
              label: 'Nom de la catégorie',
              icon: Icons.label,
            ),
            const SizedBox(height: 16),
            const Text('Choisissez une icône'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableIcons.map((iconData) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedIcon = iconData['name'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedIcon == iconData['name']
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          iconData['icon'],
                          size: 32,
                          color: selectedIcon == iconData['name']
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          iconData['label'],
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedIcon == iconData['name']
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              widget.onSubmit(nameController.text, selectedIcon);
            }
          },
          child: Text(widget.initialName == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }
}
