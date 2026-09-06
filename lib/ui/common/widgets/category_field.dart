import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/values/category_display.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';

class CategoryField extends StatelessWidget {
  const CategoryField({required this.category, required this.onTap, super.key});
  final CategoryDisplay? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final CategoryDisplay? category = this.category;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            CategoryIcon(
              icon: category == null
                  ? Symbols.category_rounded
                  : CategoryDefaults.resolveIcon(category.icon),
              color: category == null
                  ? scheme.onSurfaceVariant
                  : Color(category.color),
              size: CategoryIconSize.sm,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category == null
                    ? 'Choisir une catégorie'
                    : '${category.groupLabel} · ${category.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: category == null ? scheme.onSurfaceVariant : null,
                ),
              ),
            ),
            Icon(
              Symbols.chevron_right_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
