import 'package:flutter/material.dart';
import 'package:mybudget/core/services/preferences_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  int _currentPage = 0;
  int get currentPage => _currentPage;

  final PageController pageController = PageController();

  void onPageChanged(int index) {
    _currentPage = index;
    notifyListeners();
  }

  void nextPage() {
    pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> completeOnboarding() async {
    await PreferencesService.setNotFirstLaunch();
  }
}
