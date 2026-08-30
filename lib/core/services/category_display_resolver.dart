import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/utils/text_normalizer.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/models/category_override_model.dart';

/// A taxonomy node ready to be rendered, user customisation applied.
class CategoryDisplay {
  final String slug;
  final String label;
  final String icon;
  final int color;
  final String groupKey;
  final String groupLabel;
  final TransactionType type;

  const CategoryDisplay({
    required this.slug,
    required this.label,
    required this.icon,
    required this.color,
    required this.groupKey,
    required this.groupLabel,
    required this.type,
  });

  bool get isGroup => slug == groupKey;
}

/// Merges the taxonomy asset with the sparse user overrides.
///
/// Overrides are keyed by slug: a bare `alimentation` targets the group, a
/// dotted `alimentation.supermarche` targets the leaf. Colour is a group-level
/// property: a leaf always follows its group, so restyling a group restyles its
/// children and no leaf can drift out of its group's identity.
class CategoryDisplayResolver {
  /// Bucket for transactions with no slug, or a slug the taxonomy no longer
  /// knows. Surfaced rather than dropped: a silently missing amount makes the
  /// breakdown stop summing to the total with nothing to explain the gap.
  static const String uncategorizedKey = '__uncategorized__';
  static const String uncategorizedLabel = 'Non catégorisé';
  static const int uncategorizedColor = 0xFF9E9E9E;
  static const String uncategorizedIcon = 'category';

  final CategoryTaxonomyService _taxonomy;
  final Map<String, CategoryOverrideModel> _overrides;

  const CategoryDisplayResolver({
    required this._taxonomy,
    required this._overrides,
  });

  /// Resolves a leaf slug, or null when it is unknown.
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

  /// Resolves the group owning a leaf slug, aliases followed.
  CategoryDisplay? resolveGroupOfSlug(String slug) {
    final group = _taxonomy.groupOfSlug(slug);
    return group == null ? null : resolveGroup(group.key);
  }

  /// Group key owning [slug], falling back to [uncategorizedKey].
  ///
  /// The single definition of what "no category" means, so aggregation and
  /// filtering cannot disagree.
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

  /// Group key owning [slug], or null when the slug is unknown.
  ///
  /// Aggregation must go through here rather than splitting the slug: a node
  /// moved to another group keeps its old prefix but belongs to the new group.
  String? groupKeyOf(String slug) => _taxonomy.groupOfSlug(slug)?.key;

  /// Groups of [type], or every group, expenses first, when it is null.
  List<CategoryDisplay> groupsOfType(TransactionType? type) => _taxonomy
      .groupsOfType(type)
      .map((group) => resolveGroup(group.key)!)
      .toList();

  /// The same taxonomy with every customisation dropped.
  ///
  /// The single source of "what would this look like by default", so the edit
  /// form can drop a field that matches instead of storing it again.
  CategoryDisplayResolver get withoutOverrides =>
      CategoryDisplayResolver(taxonomy: _taxonomy, overrides: const {});

  CategoryDisplay defaultsOf(CategoryDisplay category) => category.isGroup
      ? withoutOverrides.resolveGroup(category.groupKey)!
      : withoutOverrides.resolve(category.slug)!;

  /// Selectable leaves of [type], or of both types when it is null, whose
  /// label or whose group label matches [query]. Empty for a blank query: the
  /// caller keeps showing the tree.
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
