import 'package:app_updater/app_updater.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/objectbox_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAppUpdater extends Mock implements AppUpdater {}

Future<void> initializeTestApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'isFirstLaunch': false,
    'isCategoriesCreated': true,
  });
  await PreferencesService.init();
  await initializeDateFormatting('fr_FR', null);

  final obs = await ObjectBoxService.getInstance();
  await obs.clearAllData();

  final mockUpdater = _MockAppUpdater();
  when(() => mockUpdater.currentVersion).thenReturn('1.0.0');
  when(() => mockUpdater.checkForUpdates()).thenAnswer((_) async => null);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        objectBoxServiceProvider.overrideWith((ref) => Future.value(obs)),
        appUpdaterProvider.overrideWithValue(mockUpdater),
      ],
      child: const _TestApp(),
    ),
  );

  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> resetAppState() async {
  final obs = await ObjectBoxService.getInstance();
  await obs.clearAllData();
}

class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectBoxAsync = ref.watch(objectBoxServiceProvider);

    return objectBoxAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text('Error: $e'),
      ),
      data: (_) {
        final themeState = ref.watch(themeProvider);
        final themeNotifier = ref.read(themeProvider.notifier);

        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'My Budget - Test',
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('fr')],
              theme: themeNotifier.getLightTheme(dynamicColorScheme: lightDynamic),
              darkTheme: themeNotifier.getDarkTheme(dynamicColorScheme: darkDynamic),
              themeMode: themeState.themeMode,
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
