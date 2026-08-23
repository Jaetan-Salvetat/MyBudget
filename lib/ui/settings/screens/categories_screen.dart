import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'package:mybudget/ui/common/widgets/category_tile.dart';
import 'package:mybudget/ui/common/widgets/expandable_group.dart';
import 'package:mybudget/ui/common/widgets/search_input.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/settings/screens/category_form_screen.dart';

/// Read-only taxonomy tree. Categories cannot be created or deleted: the
/// taxonomy is the contract with the classifier. Only name, icon and colour
/// can be customised.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _openGroupKey;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overrides = ref.watch(categoryOverrideProvider).value ?? const {};

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Catégories',
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          FrostedTopBar.bodyTopPadding(context) + 12,
          16,
          0,
        ),
        child: ref
            .watch(categoryDisplayResolverProvider)
            .when(
              loading: () => const Center(child: FrostedCircularProgress()),
              error: (error, _) => Center(child: Text('Erreur : $error')),
              data: (resolver) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchInput(
                    controller: _searchController,
                    hintText: 'Rechercher une catégorie…',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _tree(resolver, overrides)),
                ],
              ),
            ),
      ),
    );
  }

  Widget _tree(
    CategoryDisplayResolver resolver,
    Map<String, CategoryOverrideModel> overrides,
  ) {
    final matches = _matchingLeavesByGroup(resolver);

    if (matches.isEmpty) {
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

    final searching = _query.trim().isNotEmpty;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final entry in matches.entries)
          _GroupSection(
            group: resolver.resolveGroup(entry.key)!,
            children: entry.value,
            overrides: overrides,
            expanded: searching || _openGroupKey == entry.key,
            collapsible: !searching,
            onToggle: () => setState(
              () =>
                  _openGroupKey = _openGroupKey == entry.key ? null : entry.key,
            ),
            onEdit: (category) => _edit(resolver, category),
          ),
      ],
    );
  }

  /// Leaves to show per group key, in taxonomy order, expenses before income.
  ///
  /// A search keeps the tree shape rather than flattening it: the group row is
  /// what carries the colour, so it has to stay reachable to be edited.
  Map<String, List<CategoryDisplay>> _matchingLeavesByGroup(
    CategoryDisplayResolver resolver,
  ) {
    final query = _query.trim();
    final result = <String, List<CategoryDisplay>>{};

    for (final type in TransactionType.values) {
      if (query.isEmpty) {
        for (final group in resolver.groupsOfType(type)) {
          result[group.groupKey] = resolver.childrenOf(group.groupKey);
        }
        continue;
      }

      for (final leaf in resolver.search(query, type)) {
        result.putIfAbsent(leaf.groupKey, () => []).add(leaf);
      }
    }

    return result;
  }

  Future<void> _edit(
    CategoryDisplayResolver resolver,
    CategoryDisplay category,
  ) async {
    final action = await CategoryFormScreen.push(
      context: context,
      initial: category,
      defaults: resolver.defaultsOf(category),
    );
    if (action == null || !mounted) return;

    final notifier = ref.read(categoryOverrideProvider.notifier);
    try {
      await switch (action) {
        CategoryReset() => notifier.reset(category.slug),
        CategoryCustomisation(:final name, :final icon, :final color) =>
          notifier.customize(
            category.slug,
            name: name,
            icon: icon,
            color: color,
          ),
      };
    } catch (error) {
      if (!mounted) return;
      FrostedSnackbar.show(
        context,
        message: 'Personnalisation non enregistrée : $error',
      );
    }
  }
}

class _GroupSection extends StatelessWidget {
  final CategoryDisplay group;
  final List<CategoryDisplay> children;
  final Map<String, CategoryOverrideModel> overrides;
  final bool expanded;
  final bool collapsible;
  final VoidCallback onToggle;
  final ValueChanged<CategoryDisplay> onEdit;

  const _GroupSection({
    required this.group,
    required this.children,
    required this.overrides,
    required this.expanded,
    required this.collapsible,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableGroup(
      expanded: expanded,
      header: CategoryTile(
        category: group,
        onTap: collapsible ? onToggle : null,
        trailing: _Trailing(
          customised: overrides.containsKey(group.slug),
          showChevron: collapsible,
          expanded: expanded,
          onEdit: () => onEdit(group),
        ),
      ),
      children: [
        for (final child in children)
          CategoryTile(
            category: child,
            indented: true,
            trailing: _Trailing(
              customised: overrides.containsKey(child.slug),
              onEdit: () => onEdit(child),
            ),
          ),
      ],
    );
  }
}

class _Trailing extends StatelessWidget {
  final bool customised;
  final bool showChevron;
  final bool expanded;
  final VoidCallback onEdit;

  const _Trailing({
    required this.customised,
    required this.onEdit,
    this.showChevron = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (customised)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Symbols.edit_rounded, size: 14, color: scheme.primary),
          ),
        Tooltip(
          message: 'Personnaliser',
          child: FrostedIconButton.standard(
            icon: Symbols.tune_rounded,
            size: FrostedIconButtonSize.small,
            onPressed: onEdit,
          ),
        ),
        if (showChevron) ExpandChevron(expanded: expanded),
      ],
    );
  }
}
