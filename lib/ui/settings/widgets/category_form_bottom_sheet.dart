import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/category_model.dart';

class CategoryFormBottomSheet extends StatefulWidget {
  final CategoryModel? initial;
  final void Function(String name, int color, String icon) onSubmit;

  const CategoryFormBottomSheet({
    required this.onSubmit,
    this.initial,
    super.key,
  });

  static void show({
    required BuildContext context,
    CategoryModel? initial,
    required void Function(String name, int color, String icon) onSubmit,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: initial == null ? 'Nouvelle catégorie' : 'Modifier la catégorie',
      child: CategoryFormBottomSheet(initial: initial, onSubmit: onSubmit),
    );
  }

  @override
  State<CategoryFormBottomSheet> createState() =>
      _CategoryFormBottomSheetState();
}

class _CategoryFormBottomSheetState extends State<CategoryFormBottomSheet> {
  late TextEditingController _nameController;
  late int _selectedColor;
  late String _selectedIcon;

  static const List<int> _colors = [
    0xFFEF5350, // rouge
    0xFFEC407A, // rose
    0xFFAB47BC, // violet
    0xFF7E57C2, // violet foncé
    0xFF42A5F5, // bleu
    0xFF26C6DA, // cyan
    0xFF26A69A, // teal
    0xFF66BB6A, // vert
    0xFFD4E157, // vert clair
    0xFFFFCA28, // jaune
    0xFFFFA726, // orange
    0xFF8D6E63, // marron
    0xFF78909C, // bleu-gris
    0xFF9E9E9E, // gris
  ];

  static final List<IconData> _icons = [
    Icons.home,
    Icons.restaurant,
    Icons.directions_car,
    Icons.shopping_bag,
    Icons.medical_services,
    Icons.sports_esports,
    Icons.movie,
    Icons.school,
    Icons.flight_takeoff,
    Icons.fitness_center,
    Icons.checkroom,
    Icons.pets,
    Icons.wifi,
    Icons.phone_android,
    Icons.local_gas_station,
    Icons.child_care,
    Icons.account_balance_wallet,
    Icons.subscriptions,
    Icons.local_cafe,
    Icons.more_horiz,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _selectedColor = widget.initial?.color ?? _colors[4]; // bleu par défaut
    _selectedIcon = widget.initial?.icon ?? _icons.last.codePoint.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconStr) {
    if (RegExp(r'^\d+$').hasMatch(iconStr)) {
      return IconData(int.parse(iconStr), fontFamily: 'MaterialIcons');
    }
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      children: [
        // Aperçu
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Color(_selectedColor).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconData(_selectedIcon),
              color: Color(_selectedColor),
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Nom
        FrostedTextField(
          controller: _nameController,
          labelText: 'Nom de la catégorie',
          prefixIcon: const Icon(Icons.label_outline),
        ),
        const SizedBox(height: 24),

        // Sélecteur de couleur
        Text(
          'Couleur',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _colors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(color),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 2.5,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(color).withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Sélecteur d'icône
        Text(
          'Icône',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _icons.map((iconData) {
            final codePointStr = iconData.codePoint.toString();
            final isSelected = _selectedIcon == codePointStr;
            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = codePointStr),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(_selectedColor).withValues(alpha: 0.15)
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: Color(_selectedColor), width: 2)
                      : null,
                ),
                child: Icon(
                  iconData,
                  color: isSelected
                      ? Color(_selectedColor)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // Bouton valider
        SizedBox(
          width: double.infinity,
          child: FrostedFilledButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                widget.onSubmit(
                  _nameController.text.trim(),
                  _selectedColor,
                  _selectedIcon,
                );
                Navigator.pop(context);
              }
            },
            child: Text(widget.initial == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
