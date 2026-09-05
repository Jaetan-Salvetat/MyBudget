import 'dart:async';

import 'package:app_updater/app_updater.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/core/enums/build_flavor.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/home_widget/home_widget_provider.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };

      await PreferencesService.init();
      await ApiKeyService().migrateLegacyGeminiKey();
      await initializeDateFormatting('fr_FR', null);

      final flavor = BuildFlavor.current;
      final packageInfo = await PackageInfo.fromPlatform();

      runApp(
        ProviderScope(
          overrides: [
            buildFlavorProvider.overrideWithValue(flavor),
            appVersionProvider.overrideWithValue(packageInfo.version),
            if (flavor.supportsInAppUpdate)
              appUpdaterProvider.overrideWithValue(await _initUpdater(flavor)),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}

Future<AppUpdater> _initUpdater(BuildFlavor flavor) {
  return AppUpdater.initialize(
    UpdateConfig(
      githubOwner: 'Jaetan-Salvetat',
      githubRepo: 'MyBudget',
      channel: flavor == BuildFlavor.beta
          ? UpdateChannel.beta
          : UpdateChannel.stable,
      versionComparator: _isNewerVersion,
    ),
  );
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

class _AppContent extends ConsumerStatefulWidget {
  const _AppContent();

  @override
  ConsumerState<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends ConsumerState<_AppContent> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _refreshDatedState);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _refreshDatedState() => ref.invalidate(loanProvider);

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    ref.watch(homeWidgetProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'My Budget',
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('fr')],
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeState.themeMode,
      home: const SplashScreen(),
    );
  }
}
