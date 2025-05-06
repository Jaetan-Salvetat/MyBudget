import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mybudget/presentation/screens/accounts_screen.dart';
import 'package:mybudget/presentation/screens/dashboard_screen.dart';
import 'package:mybudget/presentation/screens/expenses_screen.dart';
import 'package:mybudget/presentation/screens/revenues_screen.dart';
import 'package:mybudget/presentation/screens/settings_screen.dart';
import 'package:mybudget/presentation/screens/splash_screen.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/controllers/index.dart';
import 'package:mybudget/core/controllers/theme_controller.dart';
import 'package:mybudget/core/routes/app_routes.dart';
import 'package:mybudget/core/services/isar_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {}

  await initServices();
  initControllers();

  runApp(const MyApp());
}

Future<void> initServices() async {
  await PreferencesService.init();
  await IsarService.init();
}

void initControllers() {
  Get.put(AccountController(), permanent: true);
  Get.put(CategoryController(), permanent: true);
  Get.put(ExpenseController(), permanent: true);
  Get.put(RevenueController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  // Privacy et Auth controllers temporairement désactivés pendant la migration vers Isar
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Budget',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
        GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
        GetPage(name: AppRoutes.expenses, page: () => const ExpensesScreen()),
        GetPage(name: AppRoutes.revenues, page: () => const RevenuesScreen()),
        GetPage(name: AppRoutes.accounts, page: () => const AccountsScreen()),
        GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),

        // Écrans d'authentification temporairement désactivés pendant la migration vers Isar
        // GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
        // GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
        // GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordScreen()),
      ],
    );
  }
}
