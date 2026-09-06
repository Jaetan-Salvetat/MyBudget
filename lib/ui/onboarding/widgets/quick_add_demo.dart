import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_hint_typer.dart';
import 'package:mybudget/ui/onboarding/models/onboarding_demo.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_draft_line.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

class QuickAddDemo extends ConsumerStatefulWidget {
  static const double previewExtent = 64;

  final bool isActive;

  const QuickAddDemo({required this.isActive, super.key});

  @override
  ConsumerState<QuickAddDemo> createState() => _QuickAddDemoState();
}

class _QuickAddDemoState extends ConsumerState<QuickAddDemo> {
  final TextEditingController _controller = TextEditingController();

  late final QuickAddHintTyper _typer = QuickAddHintTyper(
    phrases: OnboardingDemo.phrases.map((phrase) => phrase.text).toList(),
  );

  @override
  void initState() {
    super.initState();
    _typer.addListener(_onTyped);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTyper();
  }

  @override
  void didUpdateWidget(QuickAddDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTyper();
  }

  @override
  void dispose() {
    _typer.removeListener(_onTyped);
    _typer.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncTyper() {
    if (widget.isActive && !MediaQuery.disableAnimationsOf(context)) {
      _typer.start();
    } else {
      _typer.pause();
    }
  }

  void _onTyped() {
    if (!mounted) return;

    setState(() => _controller.text = _typer.value);
  }

  QuickAddDemoPhrase? _phraseFor(String typed) {
    for (final phrase in OnboardingDemo.phrases) {
      if (phrase.text == typed) return phrase;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final phrase = _phraseFor(_controller.text);
    final resolver = ref.watch(categoryDisplayResolverProvider).value;
    final display = phrase == null
        ? null
        : resolver?.resolve(phrase.categorySlug);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: QuickAddDemo.previewExtent,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: QuickAddDraftLine(
              amount: phrase?.amount,
              isIncome: phrase?.type == TransactionType.income,
              category: display == null
                  ? null
                  : QuickAddCategoryPreview(
                      label: display.label,
                      icon: CategoryDefaults.resolveIcon(display.icon),
                      color: Color(display.color),
                      isUncertain: false,
                    ),
              recurrenceLabel: phrase?.frequency.label,
              dateLabel: phrase?.dateLabel,
              isStale: phrase == null && _controller.text.isNotEmpty,
              onPickCategory: null,
              onPickDate: null,
              onPickFrequency: null,
            ),
          ),
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        IgnorePointer(
          child: FrostedTextField(
            controller: _controller,
            leadingIcon: Symbols.auto_awesome_rounded,
          ),
        ),
      ],
    );
  }
}
