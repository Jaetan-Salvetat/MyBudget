import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';

void main() {
  test('every axis has a label', () {
    for (final axis in RevenueGroupBy.values) {
      expect(axis.label, isNotEmpty);
    }
  });

  test('reads back a persisted axis', () {
    expect(
      RevenueGroupBy.fromName(RevenueGroupBy.beneficiary.name),
      RevenueGroupBy.beneficiary,
    );
  });

  test('falls back to the frequency axis on an unknown or missing value', () {
    expect(RevenueGroupBy.fromName(null), RevenueGroupBy.frequency);
    expect(RevenueGroupBy.fromName('axe_supprime'), RevenueGroupBy.frequency);
  });
}
