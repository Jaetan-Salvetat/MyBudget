import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/settings/widgets/category_form_bottom_sheet.dart';

/// Read-only taxonomy tree. Categories cannot be created or deleted: the
/// taxonomy is the contract with the classifier. Only name, icon and colour
/// can be customised.
class CategoriesBottomSheet extends ConsumerWidget {
  const CategoriesBottomSheet({super.key});

  static void show(BuildContext context) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Catégories',
      child: const CategoriesBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(categoryDisplayResolverProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur : $error')),
          data: (resolver) {
            final groups = [
              ...resolver.groupsOfType(TransactionType.expense),
              ...resolver.groupsOfType(TransactionType.income),
            ];

            return ListView.builder(
              shrinkWrap: true,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _GroupSection(
                  group: group,
                  children: resolver.childrenOf(group.slug),
                );
              },
            );
          },
        );
  }
}

class _GroupSection extends ConsumerWidget {
  final CategoryDisplay group;
  final List<CategoryDisplay> children;

  const _GroupSection({required this.group, required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpansionTile(
      leading: Icon(CategoryDefaults.resolveIcon(group.icon),
          color: Color(group.color)),
      title: Text(group.label),
      trailing: _EditButton(category: group),
      children: [
        for (final child in children)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            leading: Icon(CategoryDefaults.resolveIcon(child.icon),
                size: 20, color: Color(child.color)),
            title: Text(child.label),
            trailing: _EditButton(category: child),
          ),
      ],
    );
  }
}

class _EditButton extends ConsumerWidget {
  final CategoryDisplay category;

  const _EditButton({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Symbols.edit_rounded, size: 18),
      tooltip: 'Personnaliser',
      onPressed: () => CategoryFormBottomSheet.show(
        context: context,
        initial: category,
        onSubmit: (name, color, icon) {
          ref.read(categoryOverrideProvider.notifier).customize(
                category.slug,
                name: name,
                color: color,
                icon: icon,
              );
          Navigator.pop(context);
        },
      ),
    );
  }
}
