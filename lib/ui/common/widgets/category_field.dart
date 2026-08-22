import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

/// Read-only field showing the picked category, tapping opens the picker.
class CategoryField extends ConsumerWidget {
  final String? slug;
  final VoidCallback onTap;

  const CategoryField({required this.slug, required this.onTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final resolver = ref.watch(categoryDisplayResolverProvider).value;
    final category = slug == null ? null : resolver?.resolve(slug!);

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
