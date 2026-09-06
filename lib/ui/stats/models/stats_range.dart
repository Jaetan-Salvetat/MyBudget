enum StatsRange {
  sixMonths(6, '6 mois'),
  twelveMonths(12, '12 mois');

  const StatsRange(this.months, this.label);

  final int months;
  final String label;
}
