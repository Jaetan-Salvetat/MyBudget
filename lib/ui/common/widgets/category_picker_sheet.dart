import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

/// Two-level taxonomy picker: pick a group, then one of its subcategories.
///
/// [suggestions] are shown first, above the groups, so a model prediction can
/// be confirmed in one tap.
class CategoryPickerSheet extends ConsumerStatefulWidget {
  final TransactionType type;
  final String? selectedSlug;
  final List<String> suggestions;

  const CategoryPickerSheet({
    super.key,
    this.type = TransactionType.expense,
    this.selectedSlug,
    this.suggestions = const [],
  });

  static Future<String?> show(
    BuildContext context, {
    TransactionType type = TransactionType.expense,
    String? selectedSlug,
    List<String> suggestions = const [],
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryPickerSheet(
        type: type,
        selectedSlug: selectedSlug,
        suggestions: suggestions,
      ),
    );
  }

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  String? _openGroupKey;

  @override
  void initState() {
    super.initState();
    final slug = widget.selectedSlug;
    if (slug != null && slug.contains('.')) {
      _openGroupKey = slug.split('.').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolver = ref.watch(categoryDisplayResolverProvider).value;
    if (resolver == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final suggestions = widget.suggestions
        .map(resolver.resolve)
        .whereType<CategoryDisplay>()
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Catégorie',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (suggestions.isNotEmpty) ...[
                    const _SectionLabel('Suggestions'),
                    for (final suggestion in suggestions)
                      _LeafTile(
                        category: suggestion,
                        subtitle: suggestion.groupLabel,
                        selected: suggestion.slug == widget.selectedSlug,
                        onTap: () => Navigator.pop(context, suggestion.slug),
                      ),
                    const Divider(height: 24),
                  ],
                  for (final group in resolver.groupsOfType(widget.type))
                    _GroupTile(
                      group: group,
                      children: resolver.childrenOf(group.slug),
                      expanded: _openGroupKey == group.slug,
                      selectedSlug: widget.selectedSlug,
                      onToggle: () => setState(
                        () => _openGroupKey =
                            _openGroupKey == group.slug ? null : group.slug,
                      ),
                      onPick: (slug) => Navigator.pop(context, slug),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final CategoryDisplay group;
  final List<CategoryDisplay> children;
  final bool expanded;
  final String? selectedSlug;
  final VoidCallback onToggle;
  final ValueChanged<String> onPick;

  const _GroupTile({
    required this.group,
    required this.children,
    required this.expanded,
    required this.selectedSlug,
    required this.onToggle,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(CategoryDefaults.resolveIcon(group.icon),
              color: Color(group.color)),
          title: Text(group.label),
          trailing: Icon(
            expanded ? Symbols.expand_less_rounded : Symbols.expand_more_rounded,
          ),
          onTap: onToggle,
        ),
        if (expanded)
          for (final child in children)
            _LeafTile(
              category: child,
              selected: child.slug == selectedSlug,
              indented: true,
              onTap: () => onPick(child.slug),
            ),
      ],
    );
  }
}

class _LeafTile extends StatelessWidget {
  final CategoryDisplay category;
  final String? subtitle;
  final bool selected;
  final bool indented;
  final VoidCallback onTap;

  const _LeafTile({
    required this.category,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.indented = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: indented ? 32 : 16, right: 16),
      leading: Icon(CategoryDefaults.resolveIcon(category.icon),
          color: Color(category.color), size: 20),
      title: Text(category.label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: selected
          ? Icon(Symbols.check_rounded,
              color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
