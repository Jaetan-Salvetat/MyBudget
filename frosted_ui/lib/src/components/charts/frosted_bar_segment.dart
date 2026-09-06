import 'package:material_ui/material_ui.dart';

@immutable
class FrostedBarSegment {
  const FrostedBarSegment({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is FrostedBarSegment &&
      other.value == value &&
      other.color == color;

  @override
  int get hashCode => Object.hash(value, color);
}
