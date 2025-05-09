import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mybudget/core/controllers/onboarding_controller.dart';
import 'package:mybudget/domain/entities/onboarding_page.dart';
import 'dart:ui';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            final currentPage = controller.currentPage.value;
            final backgroundColor = controller.pages[currentPage].backgroundColor;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    backgroundColor.withOpacity(0.9),
                    backgroundColor,
                    backgroundColor.withOpacity(0.85),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: BackgroundPainter(backgroundColor),
                child: PageView.builder(
                  controller: controller.pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: controller.onPageChanged,
                  itemCount: controller.pages.length,
                  itemBuilder: (context, index) {
                    final page = controller.pages[index];
                    return OnboardingPageView(page: page, index: index);
                  },
                ),
              ),
            );
          }),
          
          Positioned(
            top: screenHeight * 0.07,
            right: 20,
            child: Obx(() => AnimatedOpacity(
              opacity: controller.isLastPage.value ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: _buildSkipButton(controller),
            )),
          ),
          
          Positioned(
            bottom: screenHeight * 0.15,
            left: 0,
            right: 0,
            child: _buildPageIndicator(controller),
          ),
          
          Positioned(
            bottom: screenHeight * 0.06,
            left: 30,
            right: 30,
            child: _buildNavigation(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(OnboardingController controller) {
    return Obx(() {
      final currentPage = controller.currentPage.value;
      final backgroundColor = controller.pages[currentPage].backgroundColor;
      final isLast = controller.isLastPage.value;
      
      return Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor,
              Color.lerp(backgroundColor, Colors.white, 0.2)!,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.nextPage,
            borderRadius: BorderRadius.circular(30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLast ? "Commencer" : "Suivant",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLast ? Icons.check_circle_outline : Icons.arrow_forward,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSkipButton(OnboardingController controller) {
    return Obx(() {
      if (controller.isLastPage.value) {
        return const SizedBox.shrink();
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: TextButton(
              onPressed: controller.skipOnboarding,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "Passer",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPageIndicator(OnboardingController controller) {
    return Obx(() {
      final currentPage = controller.currentPage.value;
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          controller.pages.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: currentPage == index ? 24 : 8,
            decoration: BoxDecoration(
              color: currentPage == index 
                ? Colors.white 
                : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              boxShadow: currentPage == index ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
          ),
        ),
      );
    });
  }
}

class BackgroundPainter extends CustomPainter {
  final Color color;
  
  BackgroundPainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < 5; i++) {
      final centerX = size.width * (0.2 + 0.15 * i);
      final centerY = size.height * (0.1 + 0.2 * i);
      final radius = size.width * (0.1 + 0.03 * i);
      
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => oldDelegate.color != color;
}

class OnboardingPageView extends StatelessWidget {
  final OnboardingPage page;
  final int index;

  const OnboardingPageView({
    required this.page,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.08),
            
            Container(
              height: screenHeight * 0.35,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.75,
                    height: screenWidth * 0.75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  
                  Hero(
                    tag: "onboarding-image-$index",
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: SvgPicture.asset(
                        page.imagePath,
                        height: screenHeight * 0.25,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: screenHeight * 0.05),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          page.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 17,
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    
                    if (page.extraContent != null) page.extraContent!,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
