import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/routes/app_routes.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/objectbox_service.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/category_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/core/controllers/loan_controller.dart';
import 'package:mybudget/core/controllers/theme_controller.dart';
import 'package:mybudget/core/controllers/update_controller.dart';
import 'package:mybudget/presentation/screens/update_screen.dart';
import 'package:mybudget/presentation/screens/onboarding_screen.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final startTime = DateTime.now();

      await _loadInitialData();

      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
      const minimumDelay = 1000;

      if (elapsedTime < minimumDelay) {
        await Future.delayed(
          Duration(milliseconds: minimumDelay - elapsedTime),
        );
      }

      await navigateToDashboard();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      await PreferencesService.init();
      
      final objectBoxService = await ObjectBoxService.getInstance();
      Get.put(objectBoxService, permanent: true);
      
      Get.put(CategoryController(), permanent: true);
      Get.put(ThemeController(), permanent: true);
      
      Get.put(ExpenseController(), permanent: true);
      Get.put(RevenueController(), permanent: true);
      Get.put(LoanController(), permanent: true);
      
      Get.put(AccountController(), permanent: true);
      final accountController = Get.find<AccountController>();
      final expenseController = Get.find<ExpenseController>();
      final revenueController = Get.find<RevenueController>();
      final loanController = Get.find<LoanController>();
      
      Get.put(UpdateController(), permanent: true);

      await Future.wait([
        accountController.getAccounts(),
        expenseController.getExpenses(),
        revenueController.getRevenues(),
        loanController.fetchLoans(),
      ]);
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> navigateToDashboard() async {
    bool isFirstLaunch = PreferencesService.isFirstLaunch();
    

    final updateController = Get.put(UpdateController(), permanent: true);
    
    if (isFirstLaunch) {
      Get.offAll(() => const OnboardingScreen());
      return;
    }
    
    final hasUpdate = await updateController.checkForUpdates();
    
    if (hasUpdate) {
      Get.to(() => const UpdateScreen());
    } else {
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final background = Theme.of(context).colorScheme.surface;
    final onBackground = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Transform.rotate(
              angle: -math.pi / 8,
              child: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withOpacity(0.6),
                      secondary.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    secondary.withOpacity(0.4),
                    primary.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [primary, secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'MyBudget',
                  style: TextStyle(
                    color: onBackground,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez votre budget simplement',
                  style: TextStyle(
                    color: onBackground.withOpacity(0.7),
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
