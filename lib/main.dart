import 'dart:async';

import 'package:app_updater/app_updater.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'package:mybudget/ui/home_widget/home_widget_provider.dart';
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

    await dotenv.load();
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
      versionComparator: _isNewerVersion,
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

    final launchDetails =
        await notificationsPlugin.getNotificationAppLaunchDetails();
    final launchedFromNotification =
        launchDetails?.didNotificationLaunchApp ?? false;

    await Workmanager().initialize(UpdateWorker.callbackDispatcher);
    if (PreferencesService.isBackgroundCheckEnabled()) {
      await appUpdater.startBackgroundWorker();
    }

    runApp(
      ProviderScope(
        overrides: [
          appUpdaterProvider.overrideWithValue(appUpdater),
          launchedFromNotificationProvider
              .overrideWithValue(launchedFromNotification),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

bool _isNewerVersion(String current, String candidate) {
  final currentParts = _parseVersion(current);
  final candidateParts = _parseVersion(candidate);

  for (var i = 0; i < 3; i++) {
    if (candidateParts.$1[i] > currentParts.$1[i]) return true;
    if (candidateParts.$1[i] < currentParts.$1[i]) return false;
  }

  final currentPre = currentParts.$2;
  final candidatePre = candidateParts.$2;

  if (currentPre == null && candidatePre == null) return false;
  if (currentPre != null && candidatePre == null) return true;
  if (currentPre == null && candidatePre != null) return false;

  return _comparePre(candidatePre!) > _comparePre(currentPre!);
}

(List<int>, String?) _parseVersion(String version) {
  var cleaned = version;
  if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
    cleaned = cleaned.substring(1);
  }

  String? prerelease;
  final dashIndex = cleaned.indexOf('-');
  if (dashIndex != -1) {
    prerelease = cleaned.substring(dashIndex + 1);
    cleaned = cleaned.substring(0, dashIndex);
  }

  final parts = cleaned.split('.').map(int.parse).toList();
  while (parts.length < 3) {
    parts.add(0);
  }

  return (parts, prerelease);
}

int _comparePre(String pre) {
  final match = RegExp(r'(\d+)$').firstMatch(pre);
  return match != null ? int.parse(match.group(1)!) : 0;
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
    ref.watch(homeWidgetProvider);

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
