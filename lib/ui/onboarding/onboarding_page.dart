import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/ui/home/home_screen.dart';
import 'package:mybudget/ui/onboarding/onboarding_viewmodel.dart';
import 'package:mybudget/ui/onboarding/widgets/onboarding_slide.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: const _OnboardingContent(),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();

    return FrostedScaffold(
      child: Stack(
        children: [
          PageView(
            controller: viewModel.pageController,
            onPageChanged: viewModel.onPageChanged,
            children: const [
              OnboardingSlide(
                title: "Votre argent, sans le flou.",
                subtitle:
                    "Arrêtez de deviner. Calculez instantanément votre Reste à Vivre une fois vos charges payées.",
                icon: CupertinoIcons.scope,
              ),
              OnboardingSlide(
                title: "L'essentiel, c'est tout.",
                subtitle:
                    "Ici, on ne note pas les cafés. On gère seulement le récurrent : Loyers, Crédits, Abonnements.",
                icon: CupertinoIcons.layers_alt,
              ),
              OnboardingSlide(
                title: "Jardin Secret.",
                subtitle:
                    "Vos données ne sortent jamais de ce téléphone. Aucune connexion bancaire, aucune pub, 100% privé.",
                icon: CupertinoIcons.lock_shield,
              ),
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
                  children: List.generate(3, (index) {
                    final isActive = viewModel.currentPage == index;
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

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child:
                      viewModel.currentPage == 2
                          ? FrostedFilledButton(
                            onPressed: () async {
                              await viewModel.completeOnboarding();
                              if (context.mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "Découvrir mon Reste à Vivre",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : FrostedTonalButton(
                            onPressed: viewModel.nextPage,
                            child: const Text("Suivant"),
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
