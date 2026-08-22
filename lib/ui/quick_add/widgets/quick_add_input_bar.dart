import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
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
    final state = ref.read(quickAddProvider);
    final isLocked =
        state.isLoading ||
        state.hasError ||
        (state.hasValue && state.value != null);
    if (isLocked) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final accounts = ref.read(accountProvider).value ?? [];
    if (accounts.isEmpty) {
      widget.onNoAccount();
      return;
    }

    ref.read(quickAddProvider.notifier).parse(text);
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickAddProvider);
    final isLoading = state.isLoading;
    final hasPendingResult = state.hasValue && state.value != null;
    final isLocked = isLoading || hasPendingResult || state.hasError;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: FrostedTextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !isLocked,
            autofocus: true,
            hintText: 'Saisir : « café 3,50 », « netflix 13,99 » …',
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: FrostedSpacing.sp2),
        _FilledCircleButton(
          onTap: isLocked ? null : _submit,
          background: scheme.primary,
          foreground: scheme.onPrimary,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : Icon(
                  Symbols.arrow_forward_rounded,
                  size: 20,
                  color: scheme.onPrimary,
                ),
        ),
      ],
    );
  }
}

class _FilledCircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final Widget child;

  const _FilledCircleButton({
    required this.onTap,
    required this.background,
    required this.foreground,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}
