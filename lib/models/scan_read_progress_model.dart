class ScanReadProgress {
  final String? storeName;
  final DateTime? date;
  final double? printedTotal;

  const ScanReadProgress({this.storeName, this.date, this.printedTotal});

  bool get isEmpty =>
      storeName == null && date == null && printedTotal == null;

  ScanReadProgress copyWith({
    String? storeName,
    DateTime? date,
    double? printedTotal,
  }) {
    return ScanReadProgress(
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      printedTotal: printedTotal ?? this.printedTotal,
    );
  }
}
