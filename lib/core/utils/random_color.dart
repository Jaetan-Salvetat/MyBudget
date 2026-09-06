import 'dart:math';

const double _saturation = 0.5;
const double _lightness = 0.4;
const int _opaque = 0xFF000000;
const int _degreesPerTurn = 360;
const int _degreesPerSector = 60;

int argbFromHsl(num hue) {
  final double normalized = (hue % _degreesPerTurn).toDouble();
  final double chroma =
      (1 - (2 * _lightness - 1).abs()) * _saturation;
  final double sector = normalized / _degreesPerSector;
  final double second = chroma * (1 - (sector % 2 - 1).abs());
  final double offset = _lightness - chroma / 2;

  final (double red, double green, double blue) = switch (sector.floor()) {
    0 => (chroma, second, 0.0),
    1 => (second, chroma, 0.0),
    2 => (0.0, chroma, second),
    3 => (0.0, second, chroma),
    4 => (second, 0.0, chroma),
    _ => (chroma, 0.0, second),
  };

  int channel(double value) => ((value + offset) * 255).round();

  return _opaque |
      (channel(red) << 16) |
      (channel(green) << 8) |
      channel(blue);
}

int randomBeneficiaryColor() =>
    argbFromHsl(Random().nextDouble() * _degreesPerTurn);
