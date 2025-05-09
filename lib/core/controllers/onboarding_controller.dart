import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/routes/app_routes.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/domain/entities/onboarding_page.dart';
import 'package:mybudget/core/controllers/theme_controller.dart';
import 'package:mybudget/core/controllers/account_controller.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  final RxBool isLastPage = false.obs;
  final accountController = Get.find<AccountController>();
  final themeController = Get.find<ThemeController>();

  final List<OnboardingPage> pages = const [
    OnboardingPage(
      title: "Bienvenue dans MyBudget",
      description:
          "Prenez le contrôle de vos finances personnelles avec une solution intuitive et élégante",
      imagePath: "assets/images/onboarding/welcome.svg",
      backgroundColor: const Color(0xFF6A65FB),
      textColor: Colors.white,
    ),

    OnboardingPage(
      title: "Gérez vos comptes",
      description:
          "Ajoutez vos comptes bancaires et suivez vos soldes en un coup d'œil",
      imagePath: "assets/images/onboarding/accounts.svg",
      backgroundColor: const Color(0xFF4CC9F0),
      textColor: Colors.white,
    ),

    OnboardingPage(
      title: "Suivez vos dépenses",
      description:
          "Enregistrez facilement vos dépenses et revenus pour mieux comprendre où va votre argent",
      imagePath: "assets/images/onboarding/expenses.svg",
      backgroundColor: const Color(0xFF4361EE),
      textColor: Colors.white,
    ),

    OnboardingPage(
      title: "Analysez vos habitudes",
      description:
          "Visualisez la répartition de vos dépenses et identifiez les opportunités d'économies",
      imagePath: "assets/images/onboarding/analytics.svg",
      backgroundColor: const Color(0xFF3F37C9),
      textColor: Colors.white,
    ),
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
    isLastPage.value = index == pages.length - 1;
  }

  void nextPage() {
    if (isLastPage.value) {
      completeOnboarding();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipOnboarding() {
    PreferencesService.setNotFirstLaunch();
    Get.offAllNamed(AppRoutes.dashboard);
  }

  void completeOnboarding() {
    PreferencesService.setNotFirstLaunch();
    Get.offAllNamed(AppRoutes.dashboard);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
