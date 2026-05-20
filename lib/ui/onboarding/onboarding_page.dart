import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/home/home_screen.dart';
import 'package:mybudget/ui/onboarding/onboarding_provider.dart';
import 'package:mybudget/ui/onboarding/widgets/onboarding_lock_illustration.dart';
import 'package:mybudget/ui/onboarding/widgets/onboarding_pile_illustration.dart';
import 'package:mybudget/ui/onboarding/widgets/onboarding_reste_illustration.dart';
import 'package:mybudget/ui/onboarding/widgets/onboarding_slide.dart';

class OnboardingPage extends StatelessWidget {
  final int initialPage;

  const OnboardingPage({super.key, this.initialPage = 0});

  @override
  Widget build(BuildContext context) {
    return _OnboardingContent(initialPage: initialPage);
  }
}

class _OnboardingContent extends ConsumerStatefulWidget {
  final int initialPage;

  const _OnboardingContent({required this.initialPage});

  @override
  ConsumerState<_OnboardingContent> createState() => _OnboardingContentState();
}

class _OnboardingContentState extends ConsumerState<_OnboardingContent> {
  late final PageController _pageController;
  static const int _slideCount = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).onPageChanged(widget.initialPage);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    await PreferencesService.setHasSeenUpdateOnboarding();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingProvider);
    final isLast = currentPage == _slideCount - 1;
    final scheme = Theme.of(context).colorScheme;

    return FrostedScaffold(
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isLast)
                      FrostedTextButton(
                        onPressed: _finishOnboarding,
                        foregroundColor: scheme.onSurfaceVariant,
                        child: const Text(
                          'Passer',
                          style: TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged:
                    ref.read(onboardingProvider.notifier).onPageChanged,
                children: const [
                  OnboardingSlide(
                    title: 'Ton argent, sans le flou.',
                    body:
                        'Calcule ton Reste à Vivre instantanément. Un seul chiffre qui dit tout.',
                    illustration: OnboardingResteIllustration(),
                  ),
                  OnboardingSlide(
                    title: "L'essentiel, c'est tout.",
                    body:
                        'Loyer, crédits, abonnements, courses : tout au même endroit, jamais plus.',
                    illustration: OnboardingPileIllustration(),
                  ),
                  OnboardingSlide(
                    title: 'Jardin secret.',
                    body:
                        '100 % local sur ton téléphone. Aucune connexion bancaire. Zéro pub.',
                    illustration: OnboardingLockIllustration(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              child: Row(
                children: [
                  _PagerDots(currentIndex: currentPage, count: _slideCount),
                  const Spacer(),
                  FrostedFilledButton(
                    onPressed: isLast ? _finishOnboarding : _nextPage,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLast ? 'Commencer' : 'Suivant',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLast
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PagerDots extends StatelessWidget {
  final int currentIndex;
  final int count;

  const _PagerDots({required this.currentIndex, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(right: i < count - 1 ? 6 : 0),
          height: 6,
          width: isActive ? 22 : 6,
          decoration: BoxDecoration(
            color: isActive
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(9999),
          ),
        );
      }),
    );
  }
}
