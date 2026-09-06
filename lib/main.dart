import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/feature_flags.dart';
import 'package:mybudget/core/enums/build_flavor.dart';
import 'package:mybudget/core/formatting/locales.dart';
import 'package:mybudget/core/models/feature_flag.dart';
import 'package:mybudget/core/providers/feature_flags_provider.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/ai/api_key_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/home_widget/home_widget_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
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
      await PreferencesService.purgeUnknownFlagChoices(
        featureFlags.map((FeatureFlag flag) => flag.id).toSet(),
      );
      await ApiKeyService().migrateLegacyGeminiKey();
      await initializeDateFormatting(DisplayLocale.tag, null);

      final flavor = BuildFlavor.current;
      final packageInfo = await PackageInfo.fromPlatform();

      runApp(
        ProviderScope(
          overrides: [
            buildFlavorProvider.overrideWithValue(flavor),
            appVersionProvider.overrideWithValue(packageInfo.version),
            appBuildNumberProvider.overrideWithValue(packageInfo.buildNumber),
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
    _refreshBlocklist();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _refreshDatedState() {
    ref.invalidate(loanProvider);
    _refreshBlocklist();
  }

  void _refreshBlocklist() {
    unawaited(ref.read(flagBlocklistProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    ref.watch(homeWidgetProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'My Budget',
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('fr')],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeState.themeMode,
      home: const SplashScreen(),
    );
  }
}
