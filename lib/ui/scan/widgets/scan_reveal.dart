import 'package:material_ui/material_ui.dart';
import 'package:mybudget/ui/scan/widgets/scan_receipt_header.dart';

class ScanReveal {
  const ScanReveal._();

  static const Duration duration = Duration(milliseconds: 940);

  static const Duration settle = Duration(milliseconds: 760);

  static const Curve curve = Curves.easeOutCubic;

  static const double headerEnd = 0.45;

  static const double listStart = 0.42;

  static const double rowStep = 0.035;
  static const double rowSpan = 0.28;
  static const int rowSpanCount = 8;

  static const double rowRise = 0.13;

  static double headerOffsetOf(double availableHeight, double progress) {
    final centered = (availableHeight - ScanReceiptHeader.height) / 2;
    if (centered <= 0) return 0;
    return centered * (1 - headerProgressOf(progress));
  }

  static double headerProgressOf(double progress) =>
      _phase(progress, 0, headerEnd);

  static double listProgressOf(double progress) =>
      _phase(progress, listStart, 1);

  static double rowProgressOf(double progress, int index) {
    final rank = index.clamp(0, rowSpanCount);
    final start = listStart + rank * rowStep;
    return _phase(progress, start, start + rowSpan);
  }

  static double _phase(double progress, double start, double end) {
    if (progress <= start) return 0;
    if (progress >= end) return 1;
    return curve.transform((progress - start) / (end - start));
  }
}
