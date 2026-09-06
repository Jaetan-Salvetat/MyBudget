enum StatsRange {
  twoMonths(2, '2 mois'),
  sixMonths(6, '6 mois'),
  twelveMonths(12, '12 mois');

  final int months;
  final String label;

  const StatsRange(this.months, this.label);

  static StatsRange defaultFor(int activeMonths) =>
      activeMonths > twoMonths.months ? sixMonths : twoMonths;
}
