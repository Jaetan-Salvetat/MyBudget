import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/utils/text_normalizer.dart';
import 'package:mybudget/models/category_override_model.dart';

class CategoryDisplay {
  const CategoryDisplay({
    required this.slug,
    required this.label,
    required this.icon,
    required this.color,
    required this.groupKey,
    required this.groupLabel,
    required this.type,
  });
  final String slug;
  final String label;
  final String icon;
  final int color;
  final String groupKey;
  final String groupLabel;
  final TransactionType type;

  bool get isGroup => slug == groupKey;
}

class CategoryDisplayResolver {
  const CategoryDisplayResolver({
    required this._taxonomy,
    required this._overrides,
  });
  static const String uncategorizedKey = '__uncategorized__';
  static const String uncategorizedLabel = 'Non catégorisé';
  static const int uncategorizedColor = 0xFF9E9E9E;
  static const String uncategorizedIcon = 'category';

  final CategoryTaxonomyService _taxonomy;
  final Map<String, CategoryOverrideModel> _overrides;

  CategoryDisplay? resolve(String slug) {
    final node = _taxonomy.resolve(slug);
    if (node == null) return null;

    final override = _overrides[node.slug];
    final group = node.group;

    return CategoryDisplay(
      slug: node.slug,
      label: override?.name ?? node.label,
      icon: override?.icon ?? node.icon,
      color: _groupColor(group),
      groupKey: group.key,
      groupLabel: _groupLabel(group),
      type: group.type,
    );
  }

  CategoryDisplay? resolveGroup(String key) {
    final group = _taxonomy.group(key);
    if (group == null) return null;

    final override = _overrides[key];

    return CategoryDisplay(
      slug: group.key,
      label: override?.name ?? group.label,
      icon: override?.icon ?? group.icon,
      color: override?.color ?? group.color,
      groupKey: group.key,
      groupLabel: _groupLabel(group),
      type: group.type,
    );
  }

  CategoryDisplay? resolveGroupOfSlug(String slug) {
    final group = _taxonomy.groupOfSlug(slug);
    return group == null ? null : resolveGroup(group.key);
  }

  String groupKeyOrUncategorized(String? slug) =>
      (slug == null ? null : groupKeyOf(slug)) ?? uncategorizedKey;

  CategoryDisplay uncategorized(TransactionType type) => CategoryDisplay(
    slug: uncategorizedKey,
    label: uncategorizedLabel,
    icon: uncategorizedIcon,
    color: uncategorizedColor,
    groupKey: uncategorizedKey,
    groupLabel: uncategorizedLabel,
    type: type,
  );

  String? groupKeyOf(String slug) => _taxonomy.groupOfSlug(slug)?.key;

  List<CategoryDisplay> groupsOfType(TransactionType? type) => _taxonomy
      .groupsOfType(type)
      .map((group) => resolveGroup(group.key)!)
      .toList();

  CategoryDisplayResolver get withoutOverrides =>
      CategoryDisplayResolver(taxonomy: _taxonomy, overrides: const {});

  CategoryDisplay defaultsOf(CategoryDisplay category) => category.isGroup
      ? withoutOverrides.resolveGroup(category.groupKey)!
      : withoutOverrides.resolve(category.slug)!;

  List<CategoryDisplay> search(String query, TransactionType? type) {
    final needle = TextNormalizer.normalize(query);
    if (needle.isEmpty) return const [];

    return [
      for (final group in groupsOfType(type))
        if (TextNormalizer.normalize(group.label).contains(needle))
          ...childrenOf(group.groupKey)
        else
          ...childrenOf(group.groupKey).where(
            (leaf) => TextNormalizer.normalize(leaf.label).contains(needle),
          ),
    ];
  }

  List<CategoryDisplay> childrenOf(String groupKey) =>
      _taxonomy
          .group(groupKey)
          ?.selectableChildren
          .map((child) => resolve(child.slug)!)
          .toList() ??
      const [];

  int _groupColor(TaxonomyGroup group) =>
      _overrides[group.key]?.color ?? group.color;

  String _groupLabel(TaxonomyGroup group) =>
      _overrides[group.key]?.name ?? group.label;
}
