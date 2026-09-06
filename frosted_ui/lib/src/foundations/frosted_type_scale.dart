import 'package:flutter/painting.dart';

class FrostedTypeScale {
  const FrostedTypeScale._();

  static const String _packageName = 'frosted_ui';
  static const String _displayFamily = 'Bricolage Grotesque';
  static const String _bodyFamily = 'Geist';

  static const List<FontFeature> _displayFeatures = <FontFeature>[
    FontFeature('ss01'),
    FontFeature('ss02'),
  ];

  static const List<FontFeature> _bodyFeatures = <FontFeature>[
    FontFeature('ss01'),
  ];

  static const List<FontFeature> tabularNumeric = <FontFeature>[
    FontFeature('tnum'),
  ];

  static TextStyle _display({
    required double fontSize,
    required double height,
    required double letterSpacing,
    required double opticalSize,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: _displayFamily,
      package: _packageName,
      fontWeight: weight,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: _displayFeatures,
      fontVariations: <FontVariation>[
        FontVariation('opsz', opticalSize),
        FontVariation('wght', weight.value.toDouble()),
      ],
    );
  }

  static TextStyle _body({
    required double fontSize,
    required double height,
    required FontWeight weight,
    double letterSpacing = 0,
    List<FontFeature> features = _bodyFeatures,
  }) {
    return TextStyle(
      fontFamily: _bodyFamily,
      package: _packageName,
      fontWeight: weight,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: features,
      fontVariations: <FontVariation>[
        FontVariation('wght', weight.value.toDouble()),
      ],
    );
  }

  static final TextStyle displayLarge = _display(
    fontSize: 64,
    height: 1.04,
    letterSpacing: -1.6,
    opticalSize: 96,
  );
  static final TextStyle displayMedium = _display(
    fontSize: 48,
    height: 1.08,
    letterSpacing: -0.96,
    opticalSize: 72,
  );
  static final TextStyle displaySmall = _display(
    fontSize: 36,
    height: 1.12,
    letterSpacing: -0.72,
    opticalSize: 48,
  );

  static final TextStyle displayLargeEmphasized = displayLarge.copyWith(
    fontWeight: FontWeight.w700,
    fontVariations: <FontVariation>[
      const FontVariation('opsz', 96),
      const FontVariation('wght', 700),
    ],
  );
  static final TextStyle displayMediumEmphasized = displayMedium.copyWith(
    fontWeight: FontWeight.w700,
    fontVariations: <FontVariation>[
      const FontVariation('opsz', 72),
      const FontVariation('wght', 700),
    ],
  );
  static final TextStyle displaySmallEmphasized = displaySmall.copyWith(
    fontWeight: FontWeight.w700,
    fontVariations: <FontVariation>[
      const FontVariation('opsz', 48),
      const FontVariation('wght', 700),
    ],
  );

  static final TextStyle headlineLarge = _display(
    fontSize: 32,
    height: 1.18,
    letterSpacing: -0.48,
    opticalSize: 36,
  );
  static final TextStyle headlineMedium = _display(
    fontSize: 28,
    height: 1.22,
    letterSpacing: -0.42,
    opticalSize: 28,
  );
  static final TextStyle headlineSmall = _display(
    fontSize: 24,
    height: 1.28,
    letterSpacing: -0.36,
    opticalSize: 24,
  );

  static final TextStyle titleLarge = _body(
    fontSize: 22,
    height: 1.27,
    weight: FontWeight.w600,
    letterSpacing: -0.11,
  );
  static final TextStyle titleMedium = _body(
    fontSize: 18,
    height: 1.33,
    weight: FontWeight.w600,
    letterSpacing: -0.09,
  );
  static final TextStyle titleSmall = _body(
    fontSize: 15,
    height: 1.4,
    weight: FontWeight.w600,
    letterSpacing: -0.075,
  );

  static final TextStyle bodyLarge = _body(
    fontSize: 17,
    height: 1.5,
    weight: FontWeight.w400,
  );
  static final TextStyle bodyMedium = _body(
    fontSize: 15,
    height: 1.5,
    weight: FontWeight.w400,
  );
  static final TextStyle bodySmall = _body(
    fontSize: 13,
    height: 1.5,
    weight: FontWeight.w400,
  );

  static final TextStyle labelLarge = _body(
    fontSize: 14,
    height: 1.28,
    weight: FontWeight.w500,
    letterSpacing: 0.07,
  );
  static final TextStyle labelMedium = _body(
    fontSize: 12,
    height: 1.33,
    weight: FontWeight.w500,
    letterSpacing: 0.48,
  );
  static final TextStyle labelSmall = _body(
    fontSize: 11,
    height: 1.45,
    weight: FontWeight.w500,
    letterSpacing: 0.66,
  );
}
