import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/home/home_screen.dart';
import 'package:mybudget/ui/onboarding/onboarding_provider.dart';
import 'package:mybudget/ui/onboarding/widgets/account_setup_slide.dart';
import 'package:mybudget/ui/onboarding/widgets/onboarding_slide.dart';
import 'package:mybudget/ui/onboarding/widgets/quick_add_demo.dart';
import 'package:mybudget/ui/onboarding/widgets/receipt_demo.dart';
import 'package:mybudget/ui/onboarding/widgets/recurrence_demo.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  static const int slideCount = 4;
  static const int accountSlide = slideCount - 1;

  static const String defaultAccountName = 'Compte courant';

  static const Duration pageTransition = Duration(milliseconds: 320);

  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController(
    text: OnboardingPage.defaultAccountName,
  );
  final TextEditingController _bankController = TextEditingController();
  final FocusNode _bankFocusNode = FocusNode();

  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onAccountChanged);
    _bankController.addListener(_onAccountChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onAccountChanged);
    _bankController.removeListener(_onAccountChanged);
    _pageController.dispose();
    _nameController.dispose();
    _bankController.dispose();
    _bankFocusNode.dispose();
    super.dispose();
  }

  void _onAccountChanged() => setState(() {});

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: OnboardingPage.pageTransition,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;

    setState(() => _finishing = true);
    try {
      await ref
          .read(onboardingProvider.notifier)
          .complete(
            accountName: _nameController.text.trim(),
            bank: _bankController.text.trim(),
          );
    } catch (error) {
      if (mounted) {
        setState(() => _finishing = false);
        FrostedSnackbar.show(
          context,
          message: 'Impossible de créer le compte : $error',
        );
      }
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  bool get _canFinish =>
      !_finishing &&
      _nameController.text.trim().isNotEmpty &&
      _bankController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingProvider);
    final isAccountSlide = currentPage == OnboardingPage.accountSlide;

    return FrostedScaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FrostedSpacing.sp3,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: isAccountSlide
                      ? null
                      : FrostedButton.text(
                          label: 'Passer',
                          onPressed: () =>
                              _goToPage(OnboardingPage.accountSlide),
                        ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: ref
                    .read(onboardingProvider.notifier)
                    .onPageChanged,
                children: [
                  OnboardingSlide(
                    title: 'Dis-le comme\nça te vient.',
                    body:
                        'Une phrase, et c\'est rangé : le montant, la '
                        'catégorie et la date sont lus au fil de la frappe. '
                        'Rien n\'est enregistré tant que tu n\'envoies pas.',
                    scene: QuickAddDemo(isActive: currentPage == 0),
                  ),
                  OnboardingSlide(
                    title: 'Ce qui revient,\nrevient tout seul.',
                    body:
                        'Loyer, abonnements, assurances : dis-le une fois '
                        'avec « tous les mois » et l\'app le reporte sur '
                        'chaque mois. Tu ne le ressaisis jamais.',
                    scene: RecurrenceDemoView(isActive: currentPage == 1),
                  ),
                  OnboardingSlide(
                    title: 'Ou photographie\nle ticket.',
                    body:
                        'L\'enseigne, la date, le total et chaque article '
                        'sont lus ligne par ligne, puis catégorisés. Tu '
                        'corriges ce qu\'il faut, et tu valides.',
                    scene: ReceiptDemoView(isActive: currentPage == 2),
                  ),
                  AccountSetupSlide(
                    nameController: _nameController,
                    bankController: _bankController,
                    bankFocusNode: _bankFocusNode,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FrostedSpacing.sp5,
                FrostedSpacing.sp1,
                FrostedSpacing.sp5,
                FrostedSpacing.sp5,
              ),
              child: Row(
                children: [
                  FrostedPageIndicator(
                    count: OnboardingPage.slideCount,
                    currentIndex: currentPage,
                  ),
                  const Spacer(),
                  FrostedButton.filled(
                    label: isAccountSlide ? 'Commencer' : 'Suivant',
                    icon: isAccountSlide
                        ? Symbols.check_rounded
                        : Symbols.arrow_forward_rounded,
                    onPressed: isAccountSlide
                        ? (_canFinish ? _finish : null)
                        : () => _goToPage(currentPage + 1),
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
