import 'dart:math';

class AmountSliderScale {
  const AmountSliderScale._({required this.ceiling, required this.divisions});

  factory AmountSliderScale.forHighest(double highest) {
    if (highest <= 0) {
      return const AmountSliderScale._(
        ceiling: fallbackCeiling,
        divisions: _maxDivisions,
      );
    }

    final step = _stepFor(highest);
    final ceiling = (highest / step - _roundingTolerance).ceil() * step;
    return AmountSliderScale._(
      ceiling: ceiling,
      divisions: (ceiling / step).round(),
    );
  }
  static const double fallbackCeiling = 100;
  static const int _maxDivisions = 100;
  static const List<double> _mantissas = [1, 2, 5];
  static const double _roundingTolerance = 1e-9;

  final double ceiling;
  final int divisions;

  static double _stepFor(double highest) {
    var index = 0;
    var step = _mantissas.first;
    while (highest / step > _maxDivisions) {
      index++;
      step =
          _mantissas[index % _mantissas.length] *
          pow(10, index ~/ _mantissas.length);
    }
    return step;
  }

  (double, double) clamp(double? min, double? max) {
    final low = (min ?? 0).clamp(0, ceiling).toDouble();
    final high = (max ?? ceiling).clamp(low, ceiling).toDouble();
    return (low, high);
  }
}
