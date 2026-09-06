import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class FrostedStateTokens {
  const FrostedStateTokens({
    required this.hover,
    required this.focus,
    required this.press,
    required this.disabledForeground,
    required this.disabledBackground,
  });

  factory FrostedStateTokens.dark() {
    return const FrostedStateTokens(
      hover: Color(0x0AE6E1E9),
      focus: Color(0x14E6E1E9),
      press: Color(0x1AE6E1E9),
      disabledForeground: Color(0x61E6E1E9),
      disabledBackground: Color(0x1FE6E1E9),
    );
  }

  factory FrostedStateTokens.light() {
    return const FrostedStateTokens(
      hover: Color(0x0A1C1B20),
      focus: Color(0x141C1B20),
      press: Color(0x1A1C1B20),
      disabledForeground: Color(0x611C1B20),
      disabledBackground: Color(0x1F1C1B20),
    );
  }

  final Color hover;
  final Color focus;
  final Color press;
  final Color disabledForeground;
  final Color disabledBackground;

  FrostedStateTokens copyWith({
    Color? hover,
    Color? focus,
    Color? press,
    Color? disabledForeground,
    Color? disabledBackground,
  }) {
    return FrostedStateTokens(
      hover: hover ?? this.hover,
      focus: focus ?? this.focus,
      press: press ?? this.press,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      disabledBackground: disabledBackground ?? this.disabledBackground,
    );
  }

  static FrostedStateTokens lerp(
    FrostedStateTokens a,
    FrostedStateTokens b,
    double t,
  ) {
    return FrostedStateTokens(
      hover: Color.lerp(a.hover, b.hover, t)!,
      focus: Color.lerp(a.focus, b.focus, t)!,
      press: Color.lerp(a.press, b.press, t)!,
      disabledForeground: Color.lerp(
        a.disabledForeground,
        b.disabledForeground,
        t,
      )!,
      disabledBackground: Color.lerp(
        a.disabledBackground,
        b.disabledBackground,
        t,
      )!,
    );
  }
}
