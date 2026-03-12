import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/ui/home/home_screen.dart';
import 'package:mybudget/ui/onboarding/onboarding_provider.dart';
import 'package:mybudget/ui/onboarding/widgets/onboarding_slide.dart';
import 'package:mybudget/ui/onboarding/widgets/onboarding_update_slide.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<void> _finishOnboarding({required bool enableBackgroundCheck}) async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    await PreferencesService.setHasSeenUpdateOnboarding();
    await PreferencesService.setBackgroundCheckEnabled(enableBackgroundCheck);

    if (enableBackgroundCheck) {
      await ref.read(appUpdaterProvider).startBackgroundWorker();
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  Future<void> _activateUpdates() async {
    final status = await Permission.notification.request();
    if (!status.isGranted && mounted) {
      FrostedSnackbar.show(
        context,
        message: 'Permission refusée. Vous pourrez l\'activer plus tard dans les réglages.',
      );
    }
    await _finishOnboarding(enableBackgroundCheck: status.isGranted);
  }

  Future<void> _skipUpdates() async {
    await _finishOnboarding(enableBackgroundCheck: false);
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingProvider);

    return FrostedScaffold(
      child: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged:
                ref.read(onboardingProvider.notifier).onPageChanged,
            children: [
              const OnboardingSlide(
                title: "Votre argent, sans le flou.",
                subtitle:
                    "Arrêtez de deviner. Calculez instantanément votre Reste à Vivre une fois vos charges payées.",
                icon: CupertinoIcons.scope,
              ),
              const OnboardingSlide(
                title: "L'essentiel, c'est tout.",
                subtitle:
                    "Ici, on ne note pas les cafés. On gère seulement le récurrent : Loyers, Crédits, Abonnements.",
                icon: CupertinoIcons.layers_alt,
              ),
              const OnboardingSlide(
                title: "Jardin Secret.",
                subtitle:
                    "Vos données ne sortent jamais de ce téléphone. Aucune connexion bancaire, aucune pub, 100% privé.",
                icon: CupertinoIcons.lock_shield,
              ),
              const OnboardingUpdateSlide(),
            ],
          ),

          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isActive = currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: isActive ? 24 : 8,
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

                if (currentPage == 3) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FrostedFilledButton(
                      onPressed: _activateUpdates,
                      child: const Text(
                        'Activer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FrostedTextButton(
                      onPressed: _skipUpdates,
                      child: const Text('Plus tard'),
                    ),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FrostedTonalButton(
                      onPressed: _nextPage,
                      child: const Text('Suivant'),
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
