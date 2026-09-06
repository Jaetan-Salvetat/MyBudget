import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/data/model/quick_add_draft_model.dart';
import 'package:mybudget/data/provider/ai_settings_provider.dart';
import 'package:mybudget/data/provider/quick_add_recent_submissions_provider.dart';
import 'package:mybudget/ui/capture/quick_add_account_provider.dart';
import 'package:mybudget/ui/capture/quick_add_focus_provider.dart';
import 'package:mybudget/ui/capture/quick_add_landing.dart';
import 'package:mybudget/ui/capture/quick_add_provider.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_account_line.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_hint_typer.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_preview.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_send_action.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_thinking_border.dart';
import 'package:mybudget/ui/scan/receipt_scan_launcher.dart';

const double _kScanGap = QuickAddBar.gutter - FrostedIconButton.inset * 2;

final double _kFieldOffset =
    FrostedIconButtonSize.medium.box + QuickAddBar.gutter;

class QuickAddBar extends ConsumerStatefulWidget {
  const QuickAddBar({
    required this.focused,
    required this.onFocusChanged,
    required this.onNoAccount,
    this.hint,
    super.key,
  });
  static const double gutter = FrostedSpacing.sp4;

  final bool focused;
  final ValueChanged<bool> onFocusChanged;
  final VoidCallback onNoAccount;

  final ValueListenable<String>? hint;

  @override
  ConsumerState<QuickAddBar> createState() => QuickAddBarState();
}

class QuickAddBarState extends ConsumerState<QuickAddBar>
    with WidgetsBindingObserver {
  static const Duration sentFlash = Duration(milliseconds: 700);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _keyboardOpen = false;
  bool _submitting = false;
  bool _sentFlashing = false;
  Timer? _sentFlashTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_reportFocus);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _sentFlashTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_reportFocus);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final open = View.of(context).viewInsets.bottom > 0;
    if (open == _keyboardOpen) return;

    _keyboardOpen = open;
    if (!open && _focusNode.hasFocus) _focusNode.unfocus();
  }

  void _reportFocus() => widget.onFocusChanged(_focusNode.hasFocus);

  void _keepTyping() {}

  void _cancel() {
    _controller.clear();
    ref.read(quickAddProvider.notifier).reset();
  }

  void _onChanged(String value) {
    ref.read(quickAddProvider.notifier).onInputChanged(value);
  }

  void _onDraftChanged(QuickAddDraft? previous, QuickAddDraft next) {
    final landedConfident =
        previous != null &&
        previous.isStale &&
        !next.isStale &&
        !next.isEmpty &&
        next.categorySlug != null &&
        !next.isCategoryUncertain;
    if (landedConfident) unawaited(HapticFeedback.lightImpact());
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final draft = ref.read(quickAddProvider);
    if (!draft.isSubmittable) return;

    final accountId = ref.read(quickAddAccountProvider);
    if (accountId == null) {
      widget.onNoAccount();
      return;
    }

    final landing = QuickAddLanding.controllerOf(context);
    landing?.arm();

    setState(() => _submitting = true);
    try {
      final submission = await ref
          .read(quickAddProvider.notifier)
          .submit(accountId);
      _controller.clear();
      unawaited(HapticFeedback.mediumImpact());
      if (!mounted) {
        landing?.release();
        return;
      }
      ref.read(quickAddRecentSubmissionsProvider.notifier).push(submission);
      landing?.land();
      _flashSent();
    } on QuickAddException catch (e) {
      landing?.release();
      if (!mounted) return;
      FrostedSnackbar.show(context, message: e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _flashSent() {
    _sentFlashTimer?.cancel();
    setState(() => _sentFlashing = true);
    _sentFlashTimer = Timer(sentFlash, () {
      if (mounted) setState(() => _sentFlashing = false);
    });
  }

  Future<void> _scan() async {
    if (ref.read(quickAddAccountProvider) == null) {
      widget.onNoAccount();
      return;
    }

    _focusNode.unfocus();
    await showReceiptScanSourceSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(quickAddFocusRequestProvider, (_, _) {
      _focusNode.requestFocus();
    });
    ref.listen(quickAddProvider, _onDraftChanged);

    final draft = ref.watch(quickAddProvider);

    final motion = context.frostedTokens.motion.snappy;
    final showContext = widget.focused || !draft.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: motion.duration,
          curve: motion.curve,
          alignment: Alignment.bottomCenter,
          child: draft.isEmpty
              ? const SizedBox(width: double.infinity)
              : const Padding(
                  padding: EdgeInsets.only(bottom: FrostedSpacing.sp2),
                  child: QuickAddPreview(),
                ),
        ),
        Row(
          children: [
            Transform.translate(
              offset: const Offset(-FrostedIconButton.inset, 0),
              child: FrostedIconButton.tonal(
                icon: Symbols.photo_camera_rounded,
                shape: FrostedShape.pill,
                tooltip: 'Photographier le ticket',
                onPressed: _scan,
              ),
            ),
            const SizedBox(width: _kScanGap),
            Expanded(child: _field(draft)),
          ],
        ),
        AnimatedSize(
          duration: motion.duration,
          curve: motion.curve,
          alignment: Alignment.topCenter,
          child: showContext
              ? Padding(
                  padding: EdgeInsets.only(
                    left: _kFieldOffset,
                    top: FrostedSpacing.sp2,
                  ),
                  child: QuickAddAccountLine(onNoAccount: widget.onNoAccount),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  QuickAddSendState _sendState(QuickAddDraft draft) {
    if (_submitting) return QuickAddSendState.sending;
    if (_sentFlashing) return QuickAddSendState.sent;

    return draft.isSubmittable
        ? QuickAddSendState.ready
        : QuickAddSendState.idle;
  }

  Widget? _handles(QuickAddDraft draft) {
    final state = _sendState(draft);
    if (draft.isEmpty && state == QuickAddSendState.idle) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!draft.isEmpty)
          GestureDetector(
            onTap: _cancel,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Symbols.close_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        QuickAddSendAction(state: state, onSend: _submit),
      ],
    );
  }

  Widget _field(QuickAddDraft draft) {
    final hint = widget.hint;
    if (hint == null) {
      return _fieldWithHint(draft, QuickAddHintTyper.resting);
    }

    return ValueListenableBuilder<String>(
      valueListenable: hint,
      builder: (context, typed, _) => _fieldWithHint(draft, typed),
    );
  }

  Widget _fieldWithHint(QuickAddDraft draft, String hint) {
    final usesRemote = ref.watch(quickAddUsesRemoteProvider);

    return QuickAddThinkingBorder(
      thinking: !draft.isEmpty && draft.isStale,
      child: FrostedTextField(
        controller: _controller,
        focusNode: _focusNode,
        leadingIcon: usesRemote
            ? Symbols.cloud_rounded
            : Symbols.auto_awesome_rounded,
        trailing: _handles(draft),
        hintText: hint,
        textInputAction: TextInputAction.send,
        onChanged: _onChanged,
        onSubmitted: (_) => _submit(),
        onEditingComplete: _keepTyping,
      ),
    );
  }
}
