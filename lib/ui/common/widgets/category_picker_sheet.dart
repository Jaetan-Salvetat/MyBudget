import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/common/providers/frequent_categories_provider.dart';
import 'package:mybudget/ui/common/widgets/category_tile.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';
import 'package:mybudget/ui/common/widgets/expandable_group.dart';
import 'package:mybudget/ui/common/widgets/search_input.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

/// Two-level taxonomy picker: pick a group, then one of its subcategories.
///
/// Only leaves can be picked: a group slug stored on a transaction would not
/// resolve and the amount would fall into "Non catégorisé".
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
    return showFrostedBottomSheet<String>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: 'Catégorie',
        child: CategoryPickerSheet(
          type: type,
          selectedSlug: selectedSlug,
          suggestions: suggestions,
        ),
      ),
    );
  }

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _openGroupKey;
  bool _didOpenSelectedGroup = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolver = ref.watch(categoryDisplayResolverProvider).value;
    if (resolver == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: FrostedCircularProgress()),
      );
    }

    _openSelectedGroupOnce(resolver);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchInput(
          controller: _searchController,
          hintText: 'Rechercher une catégorie…',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: _query.trim().isEmpty
              ? _browseList(resolver)
              : _resultsList(resolver),
        ),
      ],
    );
  }

  /// The group of the current selection starts open, but only until the user
  /// touches the tree: reopening it on every rebuild would fight their taps.
  void _openSelectedGroupOnce(CategoryDisplayResolver resolver) {
    if (_didOpenSelectedGroup) return;
    _didOpenSelectedGroup = true;

    final slug = widget.selectedSlug;
    if (slug != null) _openGroupKey = resolver.groupKeyOf(slug);
  }

  Widget _resultsList(CategoryDisplayResolver resolver) {
    final results = resolver.search(_query, widget.type);

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          'Aucune catégorie',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: results.length,
      itemBuilder: (context, index) =>
          _leafTile(results[index], subtitle: results[index].groupLabel),
    );
  }

  Widget _browseList(CategoryDisplayResolver resolver) {
    final suggestions = widget.suggestions
        .map(resolver.resolve)
        .whereType<CategoryDisplay>()
        .toList();
    final suggested = suggestions.map((leaf) => leaf.slug).toSet();
    final frequent = ref
        .watch(frequentCategoriesProvider(widget.type))
        .where((leaf) => !suggested.contains(leaf.slug))
        .toList();

    return ListView(
      shrinkWrap: true,
      children: [
        if (suggestions.isNotEmpty) ...[
          const _SectionLabel('Suggestions'),
          for (final suggestion in suggestions)
            _leafTile(suggestion, subtitle: suggestion.groupLabel),
        ],
        if (frequent.isNotEmpty) ...[
          const _SectionLabel('Fréquentes'),
          for (final leaf in frequent)
            _leafTile(leaf, subtitle: leaf.groupLabel),
        ],
        if (suggestions.isNotEmpty || frequent.isNotEmpty)
          const _SectionLabel('Toutes les catégories'),
        for (final group in resolver.groupsOfType(widget.type))
          _GroupSection(
            group: group,
            children: resolver.childrenOf(group.groupKey),
            expanded: _openGroupKey == group.groupKey,
            onToggle: () => setState(
              () => _openGroupKey = _openGroupKey == group.groupKey
                  ? null
                  : group.groupKey,
            ),
            leafBuilder: _leafTile,
          ),
      ],
    );
  }

  Widget _leafTile(
    CategoryDisplay leaf, {
    String? subtitle,
    bool indented = false,
  }) {
    return CategoryTile(
      category: leaf,
      subtitle: subtitle,
      indented: indented,
      selected: leaf.slug == widget.selectedSlug,
      onTap: () => Navigator.pop(context, leaf.slug),
    );
  }
}

class _GroupSection extends StatelessWidget {
  final CategoryDisplay group;
  final List<CategoryDisplay> children;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget Function(CategoryDisplay leaf, {String? subtitle, bool indented})
  leafBuilder;

  const _GroupSection({
    required this.group,
    required this.children,
    required this.expanded,
    required this.onToggle,
    required this.leafBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableGroup(
      expanded: expanded,
      header: CategoryTile(
        category: group,
        onTap: onToggle,
        trailing: ExpandChevron(expanded: expanded),
      ),
      children: [
        for (final child in children) leafBuilder(child, indented: true),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Eyebrow(label),
    );
  }
}
