import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/controllers/auth_controller.dart';
import 'package:mybudget/core/routes/app_routes.dart';
import 'package:mybudget/core/services/data_loading_service.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkAuthAndNavigate();
    });
  }

  Future<void> checkAuthAndNavigate() async {
    try {
      await authController.getCurrentUser();

      if (authController.isAuthenticated) {
        await DataLoadingService.loadAllData();
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.phoneInput);
      }
    } catch (e) {
      Get.offAllNamed(AppRoutes.phoneInput);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final background = Theme.of(context).colorScheme.background;
    final onBackground = Theme.of(context).colorScheme.onBackground;

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
