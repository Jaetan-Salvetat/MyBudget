import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/transaction_type.dart';

typedef TaxonomyGroup = ({
  String key,
  String label,
  String icon,
  int color,
  TransactionType type,
});

class CategoryTaxonomyService {
  static const String assetPath = 'assets/categories.json';
  static const int expectedVersion = 1;
  static const String _versionKey = 'version';
  static const String _expensesSection = 'expenses';
  static const String _incomeSection = 'income';

  final Map<String, TaxonomyGroup> _groups = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;

    final jsonStr = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = json.decode(jsonStr);

    final version = data[_versionKey];
    if (version != expectedVersion) {
      throw FormatException(
        'Taxonomy version mismatch in $assetPath: '
        'expected $expectedVersion, found $version',
      );
    }

    _parseSection(data[_expensesSection], TransactionType.expense);
    _parseSection(data[_incomeSection], TransactionType.income);

    _loaded = true;
  }

  TaxonomyGroup? resolve(String taxonomyCategory) {
    assert(_loaded, 'Taxonomy not loaded. Call load() first.');
    final groupKey = taxonomyCategory.split('.').first;
    return _groups[groupKey];
  }

  void _parseSection(Map<String, dynamic>? section, TransactionType type) {
    if (section == null) return;

    for (final entry in section.entries) {
      final Map<String, dynamic> group = entry.value;
      final label = group['label'] as String?;
      final icon = group['icon'] as String?;
      final colorHex = group['color'] as String?;

      if (label == null || icon == null || colorHex == null) {
        throw FormatException(
          'Invalid taxonomy group "${entry.key}" in $assetPath',
        );
      }

      _groups[entry.key] = (
        key: entry.key,
        label: label,
        icon: icon,
        color: CategoryDefaults.hexToColor(colorHex) ??
            CategoryDefaults.defaultColor,
        type: type,
      );
    }
  }
}
