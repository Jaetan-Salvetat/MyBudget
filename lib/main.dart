import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/objectbox_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';
import 'package:mybudget/utils/restart_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PreferencesService.init();
  await initializeDateFormatting('fr_FR', null);

  runApp(
    ProviderScope(
      child: RestartWidget(
        onRestart: () async {
          await ObjectBoxService.resetInstance();
          await ObjectBoxService.getInstance();
        },
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectBoxAsync = ref.watch(objectBoxServiceProvider);

    return objectBoxAsync.when(
      loading: () => const Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(color: Colors.white),
      ),
      error: (e, _) => Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: Colors.red,
          child: Center(
            child: Text(
              'Erreur critique: $e',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
      data: (_) => const _AppContent(),
    );
  }
}

class _AppContent extends ConsumerWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'My Budget',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr')],
          theme: themeNotifier.getLightTheme(dynamicColorScheme: lightDynamic),
          darkTheme: themeNotifier.getDarkTheme(dynamicColorScheme: darkDynamic),
          themeMode: themeState.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
