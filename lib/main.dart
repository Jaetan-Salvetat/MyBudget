import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mybudget/presentation/screens/splash_screen.dart';
import 'package:mybudget/presentation/screens/home_screen.dart';
import 'package:mybudget/presentation/screens/loan_details_screen.dart';
import 'package:mybudget/presentation/screens/account_details_screen.dart';
import 'package:mybudget/presentation/screens/onboarding_screen.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await dotenv.load(fileName: '.env');

  runApp(const MyApp());
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
        GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
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
