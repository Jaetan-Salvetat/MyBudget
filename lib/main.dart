import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mybudget/presentation/screens/account_details_screen.dart';
import 'package:mybudget/presentation/screens/splash_screen.dart';
import 'package:mybudget/presentation/screens/loan_details_screen.dart';
import 'package:mybudget/presentation/screens/home_screen.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/controllers/index.dart';
import 'package:mybudget/core/controllers/theme_controller.dart';
import 'package:mybudget/core/controllers/loan_controller.dart';
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

  // Enregistrement des services dans GetX
  Get.put(IsarService(), permanent: true);
}

void initControllers() {
  // Initialiser d'abord les contrôleurs qui n'ont pas de dépendances
  Get.put(CategoryController(), permanent: true);
  Get.put(ThemeController(), permanent: true);

  // Initialiser ensuite les contrôleurs qui peuvent avoir des dépendances mutuelles
  Get.put(ExpenseController(), permanent: true);
  Get.put(RevenueController(), permanent: true);
  Get.put(LoanController(), permanent: true);

  // Initialiser en dernier le contrôleur qui dépend des autres
  Get.put(AccountController(), permanent: true);
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
      home: const SplashScreen(),
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
        GetPage(name: AppRoutes.dashboard, page: () => const HomeScreen()),
        GetPage(
          name: AppRoutes.expenses,
          page: () => const HomeScreen(initialIndex: 2),
        ),
        GetPage(
          name: AppRoutes.revenues,
          page: () => const HomeScreen(initialIndex: 3),
        ),
        GetPage(
          name: AppRoutes.accounts,
          page: () => const HomeScreen(initialIndex: 1),
        ),
        GetPage(
          name: AppRoutes.settings,
          page: () => const HomeScreen(initialIndex: 5),
        ),
        GetPage(
          name: AppRoutes.loans,
          page: () => const HomeScreen(initialIndex: 4),
        ),
        GetPage(
          name: AppRoutes.loanDetails,
          page: () => const LoanDetailsScreen(),
        ),
        GetPage(
          name: AppRoutes.accountDetails,
          page: () => const AccountDetailsScreen(),
        ),
        // Écrans d'authentification temporairement désactivés pendant la migration vers Isar
        // GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
        // GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
        // GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordScreen()),
      ],
    );
  }
}
