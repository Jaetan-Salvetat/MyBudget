import 'package:flutter/material.dart';
import 'package:mybudget/presentation/widgets/common/app_text_field.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';

class CategoryBottomSheet extends StatefulWidget {
  final String? initialName;
  final String? initialIcon;
  final Function(String, String) onSubmit;

  const CategoryBottomSheet({
    this.initialName,
    this.initialIcon,
    required this.onSubmit,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    String? initialName,
    String? initialIcon,
    required Function(String, String) onSubmit,
  }) {
    return AppModalBottomSheet.show(
      context: context,
      title: initialName == null ? 'Ajouter une catégorie' : 'Modifier la catégorie',
      content: CategoryBottomSheet(
        initialName: initialName,
        initialIcon: initialIcon,
        onSubmit: onSubmit,
      ),
      actions: const [],
    );
  }

  @override
  State<CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<CategoryBottomSheet> {
  final nameController = TextEditingController();
  String selectedIcon = 'shopping_cart';

  final List<Map<String, dynamic>> availableIcons = [
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Restaurant'},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart, 'label': 'Shopping'},
    {'name': 'directions_car', 'icon': Icons.directions_car, 'label': 'Transport'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Maison'},
    {'name': 'fitness_center', 'icon': Icons.fitness_center, 'label': 'Sport'},
    {'name': 'medical_services', 'icon': Icons.medical_services, 'label': 'Santé'},
    {'name': 'sports_esports', 'icon': Icons.sports_esports, 'label': 'Jeux'},
    {'name': 'school', 'icon': Icons.school, 'label': 'Éducation'},
    {'name': 'movie', 'icon': Icons.movie, 'label': 'Divertissement'},
    {'name': 'flight_takeoff', 'icon': Icons.flight_takeoff, 'label': 'Voyage'},
    {'name': 'checkroom', 'icon': Icons.checkroom, 'label': 'Vêtements'},
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: nameController,
          label: 'Nom de la catégorie',
          icon: Icons.label,
        ),
        const SizedBox(height: 24),
        Text(
          'Icône',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (context, index) {
              final iconData = availableIcons[index];
              final isSelected = selectedIcon == iconData['name'];
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedIcon = iconData['name'];
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        iconData['icon'],
                        size: 24,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        iconData['label'],
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppModalButton(
                label: 'Annuler',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppModalButton(
                label: widget.initialName == null ? 'Ajouter' : 'Enregistrer',
                isPrimary: true,
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    widget.onSubmit(nameController.text, selectedIcon);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
