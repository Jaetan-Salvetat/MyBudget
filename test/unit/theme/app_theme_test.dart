import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/theme/finance_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  /// The app typography is fetched from Google Fonts, which no test
  /// environment can reach. The style still carries its family name, so the
  /// load failure is irrelevant here — swallow it.
  ThemeData themeFor(Brightness brightness) {
    late ThemeData theme;
    runZonedGuarded(
      () => theme = brightness == Brightness.dark
          ? AppTheme.dark()
          : AppTheme.light(),
      (Object _, StackTrace _) {},
    );
    return theme;
  }

  group('AppTheme', () {
    test('builds on the Frosted design system tokens', () {
      for (final ThemeData theme in <ThemeData>[
        themeFor(Brightness.light),
        themeFor(Brightness.dark),
      ]) {
        expect(theme.extension<FrostedTokens>(), isNotNull);
        expect(theme.useMaterial3, isTrue);
      }
    });

    test('keeps the finance colors extension', () {
      expect(themeFor(Brightness.light).extension<FinanceColors>(), FinanceColors.light);
      expect(themeFor(Brightness.dark).extension<FinanceColors>(), FinanceColors.dark);
    });

    test('keeps the app typography over the design system default', () {
      final TextTheme textTheme = themeFor(Brightness.dark).textTheme;

      expect(textTheme.bodyMedium!.fontFamily, contains('Inter'));
    });

    test('keeps the app secondary color', () {
      expect(themeFor(Brightness.dark).colorScheme.secondary, AppTheme.secondaryColor);
      expect(themeFor(Brightness.light).colorScheme.secondary, AppTheme.secondaryColor);
    });

    test('carries each brightness', () {
      expect(themeFor(Brightness.light).brightness, Brightness.light);
      expect(themeFor(Brightness.dark).brightness, Brightness.dark);
      expect(themeFor(Brightness.light).colorScheme.brightness, Brightness.light);
      expect(themeFor(Brightness.dark).colorScheme.brightness, Brightness.dark);
    });

    test('keeps the predictive back transition on Android', () {
      expect(
        themeFor(Brightness.dark).pageTransitionsTheme.builders[TargetPlatform.android],
        isA<PredictiveBackPageTransitionsBuilder>(),
      );
    });
  });
}
