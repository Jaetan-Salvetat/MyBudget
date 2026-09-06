import 'package:flutter/material.dart' as legacy;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/flutter_material_mapper.dart';

void main() {
  const List<String> roles = <String>[
    'displayLarge',
    'displayMedium',
    'displaySmall',
    'headlineLarge',
    'headlineMedium',
    'headlineSmall',
    'titleLarge',
    'titleMedium',
    'titleSmall',
    'bodyLarge',
    'bodyMedium',
    'bodySmall',
    'labelLarge',
    'labelMedium',
    'labelSmall',
  ];

  TextStyle styleOf(String role) => TextStyle(fontFamily: role);

  Map<String, TextStyle?> rolesOf(TextTheme theme) => <String, TextStyle?>{
    'displayLarge': theme.displayLarge,
    'displayMedium': theme.displayMedium,
    'displaySmall': theme.displaySmall,
    'headlineLarge': theme.headlineLarge,
    'headlineMedium': theme.headlineMedium,
    'headlineSmall': theme.headlineSmall,
    'titleLarge': theme.titleLarge,
    'titleMedium': theme.titleMedium,
    'titleSmall': theme.titleSmall,
    'bodyLarge': theme.bodyLarge,
    'bodyMedium': theme.bodyMedium,
    'bodySmall': theme.bodySmall,
    'labelLarge': theme.labelLarge,
    'labelMedium': theme.labelMedium,
    'labelSmall': theme.labelSmall,
  };

  Map<String, TextStyle?> legacyRolesOf(legacy.TextTheme theme) =>
      <String, TextStyle?>{
        'displayLarge': theme.displayLarge,
        'displayMedium': theme.displayMedium,
        'displaySmall': theme.displaySmall,
        'headlineLarge': theme.headlineLarge,
        'headlineMedium': theme.headlineMedium,
        'headlineSmall': theme.headlineSmall,
        'titleLarge': theme.titleLarge,
        'titleMedium': theme.titleMedium,
        'titleSmall': theme.titleSmall,
        'bodyLarge': theme.bodyLarge,
        'bodyMedium': theme.bodyMedium,
        'bodySmall': theme.bodySmall,
        'labelLarge': theme.labelLarge,
        'labelMedium': theme.labelMedium,
        'labelSmall': theme.labelSmall,
      };

  const List<String> colorRoles = <String>[
    'primary',
    'onPrimary',
    'primaryContainer',
    'onPrimaryContainer',
    'primaryFixed',
    'primaryFixedDim',
    'onPrimaryFixed',
    'onPrimaryFixedVariant',
    'secondary',
    'onSecondary',
    'secondaryContainer',
    'onSecondaryContainer',
    'secondaryFixed',
    'secondaryFixedDim',
    'onSecondaryFixed',
    'onSecondaryFixedVariant',
    'tertiary',
    'onTertiary',
    'tertiaryContainer',
    'onTertiaryContainer',
    'tertiaryFixed',
    'tertiaryFixedDim',
    'onTertiaryFixed',
    'onTertiaryFixedVariant',
    'error',
    'onError',
    'errorContainer',
    'onErrorContainer',
    'surface',
    'onSurface',
    'surfaceDim',
    'surfaceBright',
    'surfaceContainerLowest',
    'surfaceContainerLow',
    'surfaceContainer',
    'surfaceContainerHigh',
    'surfaceContainerHighest',
    'onSurfaceVariant',
    'outline',
    'outlineVariant',
    'shadow',
    'scrim',
    'inverseSurface',
    'onInverseSurface',
    'inversePrimary',
    'surfaceTint',
  ];

  Map<String, Color> colorRolesOf(legacy.ColorScheme scheme) => <String, Color>{
    'primary': scheme.primary,
    'onPrimary': scheme.onPrimary,
    'primaryContainer': scheme.primaryContainer,
    'onPrimaryContainer': scheme.onPrimaryContainer,
    'primaryFixed': scheme.primaryFixed,
    'primaryFixedDim': scheme.primaryFixedDim,
    'onPrimaryFixed': scheme.onPrimaryFixed,
    'onPrimaryFixedVariant': scheme.onPrimaryFixedVariant,
    'secondary': scheme.secondary,
    'onSecondary': scheme.onSecondary,
    'secondaryContainer': scheme.secondaryContainer,
    'onSecondaryContainer': scheme.onSecondaryContainer,
    'secondaryFixed': scheme.secondaryFixed,
    'secondaryFixedDim': scheme.secondaryFixedDim,
    'onSecondaryFixed': scheme.onSecondaryFixed,
    'onSecondaryFixedVariant': scheme.onSecondaryFixedVariant,
    'tertiary': scheme.tertiary,
    'onTertiary': scheme.onTertiary,
    'tertiaryContainer': scheme.tertiaryContainer,
    'onTertiaryContainer': scheme.onTertiaryContainer,
    'tertiaryFixed': scheme.tertiaryFixed,
    'tertiaryFixedDim': scheme.tertiaryFixedDim,
    'onTertiaryFixed': scheme.onTertiaryFixed,
    'onTertiaryFixedVariant': scheme.onTertiaryFixedVariant,
    'error': scheme.error,
    'onError': scheme.onError,
    'errorContainer': scheme.errorContainer,
    'onErrorContainer': scheme.onErrorContainer,
    'surface': scheme.surface,
    'onSurface': scheme.onSurface,
    'surfaceDim': scheme.surfaceDim,
    'surfaceBright': scheme.surfaceBright,
    'surfaceContainerLowest': scheme.surfaceContainerLowest,
    'surfaceContainerLow': scheme.surfaceContainerLow,
    'surfaceContainer': scheme.surfaceContainer,
    'surfaceContainerHigh': scheme.surfaceContainerHigh,
    'surfaceContainerHighest': scheme.surfaceContainerHighest,
    'onSurfaceVariant': scheme.onSurfaceVariant,
    'outline': scheme.outline,
    'outlineVariant': scheme.outlineVariant,
    'shadow': scheme.shadow,
    'scrim': scheme.scrim,
    'inverseSurface': scheme.inverseSurface,
    'onInverseSurface': scheme.onInverseSurface,
    'inversePrimary': scheme.inversePrimary,
    'surfaceTint': scheme.surfaceTint,
  };

  final TextTheme modern = TextTheme(
    displayLarge: styleOf('displayLarge'),
    displayMedium: styleOf('displayMedium'),
    displaySmall: styleOf('displaySmall'),
    headlineLarge: styleOf('headlineLarge'),
    headlineMedium: styleOf('headlineMedium'),
    headlineSmall: styleOf('headlineSmall'),
    titleLarge: styleOf('titleLarge'),
    titleMedium: styleOf('titleMedium'),
    titleSmall: styleOf('titleSmall'),
    bodyLarge: styleOf('bodyLarge'),
    bodyMedium: styleOf('bodyMedium'),
    bodySmall: styleOf('bodySmall'),
    labelLarge: styleOf('labelLarge'),
    labelMedium: styleOf('labelMedium'),
    labelSmall: styleOf('labelSmall'),
  );

  group('FlutterMaterialMapper', () {
    test('carries every role over to the legacy text theme', () {
      final legacy.TextTheme mapped = FlutterMaterialMapper.toLegacyTextTheme(
        modern,
      );

      final Map<String, TextStyle?> mappedRoles = legacyRolesOf(mapped);
      for (final String role in roles) {
        expect(mappedRoles[role]?.fontFamily, role, reason: role);
      }
    });

    test('carries every role back from the legacy text theme', () {
      final TextTheme mapped = FlutterMaterialMapper.toTextTheme(
        FlutterMaterialMapper.toLegacyTextTheme(modern),
      );

      final Map<String, TextStyle?> mappedRoles = rolesOf(mapped);
      for (final String role in roles) {
        expect(mappedRoles[role]?.fontFamily, role, reason: role);
      }
    });

    test('keeps unset roles unset', () {
      final TextTheme mapped = FlutterMaterialMapper.toTextTheme(
        FlutterMaterialMapper.toLegacyTextTheme(const TextTheme()),
      );

      expect(rolesOf(mapped).values.every((TextStyle? s) => s == null), isTrue);
    });

    test('preserves the style payload, not only the family', () {
      const TextStyle source = TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        height: 1.2,
      );

      final TextTheme mapped = FlutterMaterialMapper.toTextTheme(
        FlutterMaterialMapper.toLegacyTextTheme(
          const TextTheme(bodyMedium: source),
        ),
      );

      expect(mapped.bodyMedium, source);
    });

    test('carries every color role over to the legacy color scheme', () {
      const Color seed = Color(0xFF2A55D3);

      for (final Brightness brightness in Brightness.values) {
        final Map<String, Color> mapped = colorRolesOf(
          FlutterMaterialMapper.toLegacyColorScheme(
            ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
          ),
        );
        final Map<String, Color> reference = colorRolesOf(
          legacy.ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
        );

        for (final String role in colorRoles) {
          expect(
            mapped[role],
            reference[role],
            reason: '${brightness.name} $role',
          );
        }
      }
    });

    test('builds a legacy theme on the mapped scheme and typography', () {
      const Color seed = Color(0xFF2A55D3);
      final ThemeData source = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        textTheme: modern,
      );

      final legacy.ThemeData mapped = FlutterMaterialMapper.toLegacyThemeData(
        source,
      );

      expect(mapped.brightness, Brightness.dark);
      expect(mapped.colorScheme.primary, source.colorScheme.primary);
      expect(mapped.colorScheme.surface, source.colorScheme.surface);
      expect(mapped.textTheme.bodyMedium?.fontFamily, 'bodyMedium');
    });
  });
}
