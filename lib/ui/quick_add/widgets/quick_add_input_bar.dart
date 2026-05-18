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
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickAddProvider);
    final isLoading = state is AsyncLoading;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.xl,
        vertical: FrostedSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: FrostedTextField(
              controller: _controller,
              focusNode: _focusNode,
              hintText: 'café 3.50, netflix 13.99...',
              prefixIcon: Icon(
                Icons.bolt,
                size: 18,
                color: colorScheme.primary,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              readOnly: isLoading,
            ),
          ),
          const SizedBox(width: FrostedSpacing.sm),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loader'),
                    width: FrostedSize.iconButton,
                    height: FrostedSize.iconButton,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                : FrostedIconButton(
                    key: const ValueKey('send'),
                    icon: Icons.send_rounded,
                    onPressed: _submit,
                  ),
          ),
        ],
      ),
    );
  }
}
