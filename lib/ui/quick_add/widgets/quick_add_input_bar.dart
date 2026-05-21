import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';

const double kQuickAddBlur = 24;

class QuickAddInputBar extends ConsumerStatefulWidget {
  final VoidCallback onNoAccount;
  final VoidCallback onScanRequested;

  const QuickAddInputBar({
    required this.onNoAccount,
    required this.onScanRequested,
    super.key,
  });

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
    final isLocked = state.isLoading ||
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

    ref.read(quickAddProvider.notifier).parseExpense(text);
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: FrostedContainer(
        borderRadius: BorderRadius.circular(9999),
        blurStrength: kQuickAddBlur,
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              _CircleButton(
                onTap: widget.onScanRequested,
                child: Icon(
                  Symbols.document_scanner_rounded,
                  size: 22,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  readOnly: isLocked,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: scheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText:
                        'Saisir : « café 3,50 », « netflix 13,99 » …',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 4),
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
                        Symbols.auto_awesome_rounded,
                        size: 20,
                        color: scheme.onPrimary,
                        fill: 1,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _CircleButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
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
