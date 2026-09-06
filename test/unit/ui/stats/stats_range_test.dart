import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/stats/models/stats_range.dart';

void main() {
  group('StatsRange.defaultFor', () {
    test('holds on two months while data covers two months at most', () {
      expect(StatsRange.defaultFor(0), StatsRange.twoMonths);
      expect(StatsRange.defaultFor(1), StatsRange.twoMonths);
      expect(StatsRange.defaultFor(2), StatsRange.twoMonths);
    });

    test('opens on six months past two months of data', () {
      expect(StatsRange.defaultFor(3), StatsRange.sixMonths);
      expect(StatsRange.defaultFor(12), StatsRange.sixMonths);
    });
  });
}
