import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_confirmation_card.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_error_card.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_input_bar.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_loading_card.dart';

class QuickAddSection extends ConsumerWidget {
  final VoidCallback onNoAccount;

  const QuickAddSection({
    required this.onNoAccount,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quickAddProvider);

    final overlay = state.when(
      data: (result) {
        if (result == null) return const SizedBox.shrink();
        return QuickAddConfirmationCard(result: result);
      },
      loading: () => const QuickAddLoadingCard(),
      error: (error, _) {
        return QuickAddErrorCard(
          message: error is QuickAddException
              ? error.message
              : 'Vérifie le format ou ajoute manuellement',
          onRetry: () => ref.read(quickAddProvider.notifier).reset(),
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.bottomCenter,
          child: overlay is SizedBox
              ? overlay
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: overlay,
                ),
        ),
        QuickAddInputBar(onNoAccount: onNoAccount),
      ],
    );
  }
}
