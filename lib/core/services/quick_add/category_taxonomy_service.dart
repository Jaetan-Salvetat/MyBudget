import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/transaction_type.dart';

class TaxonomyGroup {
  final String key;
  final String label;
  final String icon;
  final int color;
  final TransactionType type;
  final List<TaxonomyNode> children = [];

  TaxonomyGroup({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.type,
  });

  List<TaxonomyNode> get selectableChildren =>
      children.where((child) => !child.isDeprecated).toList();
}

class TaxonomyNode {
  final String slug;
  final String label;
  final String icon;
  final TaxonomyGroup group;
  final bool isDeprecated;
  final String? aliasOf;

  const TaxonomyNode({
    required this.slug,
    required this.label,
    required this.icon,
    required this.group,
    required this.isDeprecated,
    required this.aliasOf,
  });

  int get color => group.color;
}

class CategoryTaxonomyService {
  static const String assetPath = 'assets/categories.json';
  static const int expectedVersion = 1;
  static const String slugSeparator = '.';

  static const String _versionKey = 'version';
  static const String _subcategoriesKey = 'subcategories';
  static const String _labelKey = 'label';
  static const String _iconKey = 'icon';
  static const String _colorKey = 'color';
  static const String _deprecatedKey = 'deprecated';
  static const String _aliasKey = 'alias_of';
  static const Map<String, TransactionType> _sections = {
    'expenses': TransactionType.expense,
    'income': TransactionType.income,
  };

  final Map<String, TaxonomyGroup> _groups = {};
  final Map<String, TaxonomyNode> _nodes = {};

  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<TaxonomyGroup> get groups => List.unmodifiable(_groups.values);

  List<TaxonomyNode> get leaves => List.unmodifiable(_nodes.values);

  Future<void> load() async {
    if (_loaded) return;

    loadFromJson(json.decode(await rootBundle.loadString(assetPath)));
  }

  @visibleForTesting
  void loadFromJson(Map<String, dynamic> data) {
    final version = data[_versionKey];
    if (version != expectedVersion) {
      throw FormatException(
        'Taxonomy version mismatch in $assetPath: '
        'expected $expectedVersion, found $version',
      );
    }

    for (final section in _sections.entries) {
      _parseSection(data[section.key], section.value);
    }

    _loaded = true;
  }

  /// Group owning [slug], resolved through the taxonomy so an aliased node
  /// reports the group it was moved to, not the one its slug spells out.
  TaxonomyGroup? groupOfSlug(String slug) => resolve(slug)?.group;

  /// Resolves a `group.subcategory` slug to its leaf, following aliases.
  ///
  /// Returns null when the slug is malformed or unknown, so historical values
  /// never crash a screen.
  TaxonomyNode? resolve(String slug) {
    assert(_loaded, 'Taxonomy not loaded. Call load() first.');

    final node = _nodes[slug];
    if (node == null) return null;

    final alias = node.aliasOf;
    return alias == null ? node : _nodes[alias];
  }

  TaxonomyGroup? group(String key) {
    assert(_loaded, 'Taxonomy not loaded. Call load() first.');
    return _groups[key];
  }

  List<TaxonomyGroup> groupsOfType(TransactionType type) =>
      _groups.values.where((group) => group.type == type).toList();

  void _parseSection(Map<String, dynamic>? section, TransactionType type) {
    if (section == null) return;

    for (final entry in section.entries) {
      final body = entry.value as Map<String, dynamic>;
      final group = TaxonomyGroup(
        key: entry.key,
        label: _requireString(body, _labelKey, entry.key),
        icon: _requireString(body, _iconKey, entry.key),
        color:
            CategoryDefaults.hexToColor(
              _requireString(body, _colorKey, entry.key),
            ) ??
            CategoryDefaults.defaultColor,
        type: type,
      );

      final subcategories = body[_subcategoriesKey];
      if (subcategories is! Map<String, dynamic> || subcategories.isEmpty) {
        throw FormatException(
          'Taxonomy group "${entry.key}" has no subcategories in $assetPath',
        );
      }

      for (final sub in subcategories.entries) {
        final subBody = sub.value as Map<String, dynamic>;
        final slug = '${entry.key}$slugSeparator${sub.key}';
        final node = TaxonomyNode(
          slug: slug,
          label: _requireString(subBody, _labelKey, slug),
          icon: _requireString(subBody, _iconKey, slug),
          group: group,
          isDeprecated: subBody[_deprecatedKey] == true,
          aliasOf: subBody[_aliasKey] as String?,
        );
        group.children.add(node);
        _nodes[slug] = node;
      }

      _groups[entry.key] = group;
    }
  }

  String _requireString(Map<String, dynamic> body, String key, String owner) {
    final value = body[key];
    if (value is String) return value;
    throw FormatException('Missing "$key" for "$owner" in $assetPath');
  }
}
