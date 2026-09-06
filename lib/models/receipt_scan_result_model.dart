import 'package:mybudget/models/scanned_item_model.dart';

class ReceiptScanResultModel {
  ReceiptScanResultModel({
    required this.date,
    required this.items,
    this.storeName,
    this.printedTotal,
    this.verified = false,
  });
  static const double _centTolerance = 0.005;

  final String? storeName;
  final DateTime date;
  final List<ScannedItemModel> items;

  final double? printedTotal;

  final bool verified;

  double get itemsTotal =>
      items.fold(0, (sum, item) => sum + item.effectiveAmount);

  double? get gap {
    final printed = printedTotal;
    if (printed == null) return null;

    return ((printed - itemsTotal) * 100).round() / 100;
  }

  bool get hasGap {
    final difference = gap;
    return difference != null && difference.abs() >= _centTolerance;
  }

  int get pendingCount => items.where((item) => item.needsAttention).length;

  List<ScannedExpenseGroup> get groupedByCategory {
    final byslug = <String, ScannedExpenseGroup>{};
    final order = <String>[];

    for (final item in items) {
      final slug = item.categorySlug;
      if (slug == null) continue;

      final existing = byslug[slug];
      if (existing == null) {
        order.add(slug);
        byslug[slug] = ScannedExpenseGroup(
          slug: slug,
          label: item.categoryName ?? '',
          total: item.effectiveAmount,
          count: 1,
        );
        continue;
      }
      byslug[slug] = existing.plus(item.effectiveAmount);
    }

    return [for (final slug in order) byslug[slug]!];
  }

  ReceiptScanResultModel copyWith({
    String? storeName,
    DateTime? date,
    double? printedTotal,
    bool? verified,
    List<ScannedItemModel>? items,
  }) {
    return ReceiptScanResultModel(
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      printedTotal: printedTotal ?? this.printedTotal,
      verified: verified ?? this.verified,
      items: items ?? this.items,
    );
  }
}

class ScannedExpenseGroup {
  const ScannedExpenseGroup({
    required this.slug,
    required this.label,
    required this.total,
    required this.count,
  });
  final String slug;
  final String label;
  final double total;
  final int count;

  ScannedExpenseGroup plus(double amount) => ScannedExpenseGroup(
    slug: slug,
    label: label,
    total: total + amount,
    count: count + 1,
  );
}
