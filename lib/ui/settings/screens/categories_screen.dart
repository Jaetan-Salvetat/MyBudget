import 'package:material_ui/material_ui.dart';
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

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  static const Map<TransactionType, String> _typeLabels = {
    TransactionType.expense: 'Dépenses',
    TransactionType.income: 'Revenus',
  };
  static const Map<TransactionType, IconData> _typeIcons = {
    TransactionType.expense: Symbols.trending_down_rounded,
    TransactionType.income: Symbols.trending_up_rounded,
  };

  final TextEditingController _searchController = TextEditingController();
  final Set<TransactionType> _openTypes = {...TransactionType.values};
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

  void _toggleType(TransactionType type, bool open) => setState(() {
    if (open) {
      _openTypes.add(type);
    } else {
      _openTypes.remove(type);
      _openGroupKey = null;
    }
  });

  Widget _tree(
    CategoryDisplayResolver resolver,
    Map<String, CategoryOverrideModel> overrides,
  ) {
    final searching = _query.trim().isNotEmpty;
    final sections = {
      for (final type in TransactionType.values)
        type: _matchingLeavesByGroup(resolver, type),
    }..removeWhere((_, groups) => groups.isEmpty);

    if (sections.isEmpty) {
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

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final section in sections.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FrostedExpansionTile(
              title: _typeLabels[section.key]!,
              leading: Icon(_typeIcons[section.key]),
              expanded: searching || _openTypes.contains(section.key),
              onExpansionChanged: (open) => _toggleType(section.key, open),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in section.value.entries)
                    _GroupSection(
                      group: resolver.resolveGroup(entry.key)!,
                      children: entry.value,
                      overrides: overrides,
                      expanded: searching || _openGroupKey == entry.key,
                      collapsible: !searching,
                      onToggle: () => setState(
                        () => _openGroupKey = _openGroupKey == entry.key
                            ? null
                            : entry.key,
                      ),
                      onEdit: (category) => _edit(resolver, category),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Map<String, List<CategoryDisplay>> _matchingLeavesByGroup(
    CategoryDisplayResolver resolver,
    TransactionType type,
  ) {
    final query = _query.trim();
    final result = <String, List<CategoryDisplay>>{};

    if (query.isEmpty) {
      for (final group in resolver.groupsOfType(type)) {
        result[group.groupKey] = resolver.childrenOf(group.groupKey);
      }
      return result;
    }

    for (final leaf in resolver.search(query, type)) {
      result.putIfAbsent(leaf.groupKey, () => []).add(leaf);
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
