import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mybudget/presentation/screens/accounts_screen.dart';
import 'package:mybudget/presentation/screens/dashboard_screen.dart';
import 'package:mybudget/presentation/screens/expenses_screen.dart';
import 'package:mybudget/presentation/screens/revenues_screen.dart';
import 'package:mybudget/presentation/screens/settings_screen.dart';
import 'package:mybudget/presentation/screens/splash_screen.dart';
import 'package:mybudget/presentation/screens/phone_input_screen.dart';
import 'package:mybudget/presentation/screens/otp_verification_screen.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/core/controllers/index.dart';
import 'package:mybudget/core/controllers/theme_controller.dart';
import 'package:mybudget/core/services/appwrite_service.dart';
import 'package:mybudget/core/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
  }
  
  initDependencies();
  initControllers();

  runApp(const MyApp());
}

void initDependencies() {
  Get.put(AppwriteService(), permanent: true);
}

void initControllers() {
  Get.put(AuthController(), permanent: true);
  Get.put(AccountController(), permanent: true);
  Get.put(CategoryController(), permanent: true);
  Get.put(ExpenseController(), permanent: true);
  Get.put(RevenueController(), permanent: true);
  Get.put(PrivacyController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
}

// On utilise le routeurProvider défini dans auth_middleware.dart

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
        GetPage(name: AppRoutes.phoneInput, page: () => const PhoneInputScreen()),
        GetPage(name: AppRoutes.otpVerification, page: () => const OtpVerificationScreen()),
        GetPage(name: AppRoutes.expenses, page: () => const ExpensesScreen()),
        GetPage(name: AppRoutes.revenues, page: () => const RevenuesScreen()),
        GetPage(name: AppRoutes.accounts, page: () => const AccountsScreen()),
        GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
      ],
    );
  }
}
