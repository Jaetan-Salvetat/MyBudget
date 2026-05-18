import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';

class QuickAddInputBar extends ConsumerStatefulWidget {
  final VoidCallback onNoAccount;

  const QuickAddInputBar({required this.onNoAccount, super.key});

  @override
  ConsumerState<QuickAddInputBar> createState() => _QuickAddInputBarState();
}

class _QuickAddInputBarState extends ConsumerState<QuickAddInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final accounts = ref.read(accountProvider).value ?? [];
    if (accounts.isEmpty) {
      widget.onNoAccount();
      return;
    }

    ref.read(quickAddProvider.notifier).parseExpense(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickAddProvider);
    final isLoading = state is AsyncLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.md,
        vertical: FrostedSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: FrostedTextField(
              controller: _controller,
              hintText: 'Ex: café 3.50',
              prefixIcon: const Icon(Icons.bolt, size: 20),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              readOnly: isLoading,
            ),
          ),
          const SizedBox(width: FrostedSpacing.sm),
          isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FrostedIconButton(
                  icon: Icons.send,
                  onPressed: _submit,
                ),
        ],
      ),
    );
  }
}
