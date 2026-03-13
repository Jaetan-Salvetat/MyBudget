import 'dart:async';

import 'package:app_updater/app_updater.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/settings/screens/update_screen.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:workmanager/workmanager.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    await PreferencesService.init();
    await initializeDateFormatting('fr_FR', null);

    final packageInfo = await PackageInfo.fromPlatform();
    final isBeta = packageInfo.packageName.endsWith('.beta');

    final backgroundInterval = PreferencesService.getBackgroundCheckInterval();

    final appUpdater = await AppUpdater.initialize(UpdateConfig(
      githubOwner: 'Jaetan-Salvetat',
      githubRepo: 'MyBudget',
      channel: isBeta ? UpdateChannel.beta : UpdateChannel.stable,
      backgroundCheckInterval: Duration(hours: backgroundInterval),
      notificationConfig: const NotificationConfig(
        smallIcon: '@drawable/ic_notification',
      ),
    ));

    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    await notificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const UpdateScreen()),
        );
      },
    );

    await Workmanager().initialize(UpdateWorker.callbackDispatcher);
    if (PreferencesService.isBackgroundCheckEnabled()) {
      await appUpdater.startBackgroundWorker();
    }

    runApp(
      ProviderScope(
        overrides: [
          appUpdaterProvider.overrideWithValue(appUpdater),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
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
          navigatorKey: navigatorKey,
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
