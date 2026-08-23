import 'package:material_ui/material_ui.dart';

import '../foundations/frosted_type_scale.dart';

/// Build a Material [TextTheme] backed by the Glass Expressive type scale.
///
/// `displayLarge` through `labelSmall` map 1:1 with the corresponding
/// [FrostedTypeScale] entries.
TextTheme buildFrostedTextTheme() {
  return TextTheme(
    displayLarge: FrostedTypeScale.displayLarge,
    displayMedium: FrostedTypeScale.displayMedium,
    displaySmall: FrostedTypeScale.displaySmall,
    headlineLarge: FrostedTypeScale.headlineLarge,
    headlineMedium: FrostedTypeScale.headlineMedium,
    headlineSmall: FrostedTypeScale.headlineSmall,
    titleLarge: FrostedTypeScale.titleLarge,
    titleMedium: FrostedTypeScale.titleMedium,
    titleSmall: FrostedTypeScale.titleSmall,
    bodyLarge: FrostedTypeScale.bodyLarge,
    bodyMedium: FrostedTypeScale.bodyMedium,
    bodySmall: FrostedTypeScale.bodySmall,
    labelLarge: FrostedTypeScale.labelLarge,
    labelMedium: FrostedTypeScale.labelMedium,
    labelSmall: FrostedTypeScale.labelSmall,
  );
}
