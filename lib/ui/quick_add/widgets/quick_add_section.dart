import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_confirmation_card.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_input_bar.dart';

class QuickAddSection extends ConsumerWidget {
  final VoidCallback onNoAccount;

  const QuickAddSection({required this.onNoAccount, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quickAddProvider);

    return FrostedContainer(
      borderRadius: BorderRadius.zero,
      showBorder: false,
      showShadow: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: state.when(
              data: (result) {
                if (result == null) return const SizedBox.shrink();
                return QuickAddConfirmationCard(result: result);
              },
              loading: () => const SizedBox.shrink(),
              error: (error, _) => _QuickAddErrorBanner(
                message: error is QuickAddException
                    ? error.message
                    : 'Une erreur est survenue',
                onDismiss: () => ref.read(quickAddProvider.notifier).reset(),
              ),
            ),
          ),
          QuickAddInputBar(onNoAccount: onNoAccount),
        ],
      ),
    );
  }
}

class _QuickAddErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _QuickAddErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FrostedSpacing.xl,
        FrostedSpacing.sm,
        FrostedSpacing.xl,
        0,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: colorScheme.error),
          const SizedBox(width: FrostedSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.error),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
