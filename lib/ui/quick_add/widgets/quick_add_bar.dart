import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/models/quick_add_draft_model.dart';
import 'package:mybudget/ui/quick_add/quick_add_account_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_focus_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_account_line.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_preview.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_submission_ticker.dart';
import 'package:mybudget/ui/scan/receipt_scan_launcher.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';

/// The one place a transaction gets typed. Reads the text as it comes,
/// creates on submit, and keeps the keyboard up : entering the day's expenses
/// is a rafale, not one trip per line. The way back sits in the ticker below.
class QuickAddBar extends ConsumerStatefulWidget {
  final bool focused;
  final ValueChanged<bool> onFocusChanged;
  final VoidCallback onNoAccount;

  const QuickAddBar({
    required this.focused,
    required this.onFocusChanged,
    required this.onNoAccount,
    super.key,
  });

  @override
  ConsumerState<QuickAddBar> createState() => QuickAddBarState();
}

class QuickAddBarState extends ConsumerState<QuickAddBar>
    with WidgetsBindingObserver {
  /// How long the send button holds its check before offering to send again.
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

  /// The system back button hides the keyboard without dropping focus, which
  /// would leave the screen in its typing layout with nothing to type on.
  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final open = View.of(context).viewInsets.bottom > 0;
    if (open == _keyboardOpen) return;

    _keyboardOpen = open;
    if (!open && _focusNode.hasFocus) _focusNode.unfocus();
  }

  void _reportFocus() => widget.onFocusChanged(_focusNode.hasFocus);

  void _cancel() {
    _controller.clear();
    ref.read(quickAddProvider.notifier).reset();
    _focusNode.unfocus();
  }

  /// Une dégradation ne se signale qu'au moment où elle arrive, et jamais
  /// pendant une saisie en cours : la transaction, elle, est passée.
  void _onDegradationChanged(bool? previous, bool degraded) {
    if (!degraded || previous == true || !mounted) return;

    FrostedSnackbar.show(
      context,
      message: 'L\'ajout rapide est repassé sur l\'appareil.',
    );
  }

  void _onChanged(String value) {
    ref.read(quickAddProvider.notifier).onInputChanged(value);
  }

  /// The moment the model catches up with a category it stands behind : worth
  /// a tap under the finger, the transaction is ready as typed.
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

  /// Submitting waits for the reading the model still owes on the current
  /// text, so the button stays busy instead of swallowing the tap. The focus
  /// stays : the next expense types straight away, the ticker holds the undo.
  Future<void> _submit() async {
    if (_submitting) return;
    if (!ref.read(quickAddProvider).isSubmittable) return;

    final accountId = ref.read(quickAddAccountProvider);
    if (accountId == null) {
      widget.onNoAccount();
      return;
    }

    setState(() => _submitting = true);
    try {
      final submission = await ref
          .read(quickAddProvider.notifier)
          .submit(accountId);
      _controller.clear();
      unawaited(HapticFeedback.mediumImpact());
      if (!mounted) return;
      ref.read(quickAddRecentSubmissionsProvider.notifier).push(submission);
      _flashSent();
    } on QuickAddException catch (e) {
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

  /// Tant que rien n'est saisi, le bouton d'envoi n'a rien à envoyer : il
  /// sert alors de raccourci vers le scan, sans occuper de place en plus.
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
    ref.listen(quickAddDegradationProvider, _onDegradationChanged);
    ref.listen(quickAddProvider, _onDraftChanged);

    final draft = ref.watch(quickAddProvider);
    final usesRemote = ref.watch(quickAddUsesRemoteProvider);
    final offersScan =
        draft.isEmpty && ref.watch(receiptScanAvailableProvider);
    final scheme = Theme.of(context).colorScheme;

    final motion = context.frostedTokens.motion.snappy;
    final showContext = widget.focused || !draft.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: motion.duration,
          curve: motion.curve,
          alignment: Alignment.topCenter,
          child: showContext
              ? Padding(
                  padding: const EdgeInsets.only(bottom: FrostedSpacing.sp1),
                  child: QuickAddAccountLine(onNoAccount: widget.onNoAccount),
                )
              : const SizedBox(width: double.infinity),
        ),
        Row(
          children: [
            Expanded(
              child: FrostedTextField(
                controller: _controller,
                focusNode: _focusNode,
                leadingIcon: usesRemote
                    ? Symbols.cloud_rounded
                    : Symbols.auto_awesome_rounded,
                trailingIcon: showContext ? Symbols.close_rounded : null,
                onTrailingTap: _cancel,
                hintText: 'café 3,50 · netflix 13,99 · salaire 2500',
                textInputAction: TextInputAction.send,
                onChanged: _onChanged,
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: FrostedSpacing.sp2),
            _TrailingButton(
              icon: _trailingIcon(offersScan),
              enabled: _sentFlashing || offersScan || draft.isSubmittable,
              busy: _submitting,
              onTap: _onTrailingTap(offersScan),
              background: scheme.primary,
              foreground: scheme.onPrimary,
            ),
          ],
        ),
        AnimatedSize(
          duration: motion.duration,
          curve: motion.curve,
          alignment: Alignment.topCenter,
          child: draft.isEmpty
              ? const SizedBox(width: double.infinity)
              : const Padding(
                  padding: EdgeInsets.only(top: FrostedSpacing.sp3),
                  child: QuickAddPreview(),
                ),
        ),
        const QuickAddSubmissionTicker(),
      ],
    );
  }

  /// The check holds the button just long enough to say "parti", then gives
  /// the send back : a rafale never waits on it.
  IconData _trailingIcon(bool offersScan) {
    if (_sentFlashing) return Symbols.check_rounded;
    if (offersScan) return Symbols.photo_camera_rounded;
    return Symbols.arrow_upward_rounded;
  }

  VoidCallback _onTrailingTap(bool offersScan) {
    if (_sentFlashing) return () {};
    return offersScan ? _scan : _submit;
  }
}

class _TrailingButton extends StatelessWidget {
  static const double _size = 44;

  static const double _spinnerSize = 18;
  static const double _spinnerStroke = 2;

  final IconData icon;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  const _TrailingButton({
    required this.icon,
    required this.enabled,
    required this.busy,
    required this.onTap,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final motion = context.frostedTokens.motion.snappy;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: motion.duration,
      curve: motion.curve,
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: enabled ? background : scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled && !busy ? onTap : null,
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedSwitcher(
              duration: motion.duration,
              switchInCurve: motion.curve,
              child: busy
                  ? SizedBox(
                      key: const ValueKey('busy'),
                      width: _spinnerSize,
                      height: _spinnerSize,
                      child: CircularProgressIndicator(
                        strokeWidth: _spinnerStroke,
                        color: foreground,
                      ),
                    )
                  : Icon(
                      icon,
                      key: ValueKey(icon),
                      size: 20,
                      color: enabled
                          ? foreground
                          : scheme.onSurface.withValues(alpha: 0.38),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
