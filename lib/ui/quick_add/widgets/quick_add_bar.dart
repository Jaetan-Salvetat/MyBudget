import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
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
import 'package:mybudget/ui/quick_add/widgets/quick_add_thinking_border.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';
import 'package:mybudget/ui/scan/receipt_scan_launcher.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';

/// The one place a transaction gets typed. Reads the text as it comes,
/// creates on submit, and keeps the keyboard up : entering the day's expenses
/// is a rafale, not one trip per line. The way back sits on the journal line
/// the transaction just became.
class QuickAddBar extends ConsumerStatefulWidget {
  static const String staticHint = 'café 3,50 · netflix 13,99 · salaire 2500';

  final bool focused;
  final ValueChanged<bool> onFocusChanged;
  final VoidCallback onNoAccount;

  /// The hint typing itself out while the day is still empty. Falls back to
  /// [staticHint] as soon as it has nothing to say.
  final ValueListenable<String>? hint;

  const QuickAddBar({
    required this.focused,
    required this.onFocusChanged,
    required this.onNoAccount,
    this.hint,
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

  /// The keyboard's send key must behave like the send button : without this,
  /// the framework's default action handling unfocuses the field and the
  /// rafale dies on the very key made for it.
  void _keepTyping() {}

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
  /// stays : the next expense types straight away, the journal holds the undo.
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

  /// Le scan est le second geste de la page, pas un raccourci caché derrière
  /// un bouton qui change de sens : il a le sien, à gauche du champ.
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
    final scheme = Theme.of(context).colorScheme;

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
                  padding: EdgeInsets.only(bottom: FrostedSpacing.sp3),
                  child: QuickAddPreview(),
                ),
        ),
        Row(
          children: [
            _RoundButton(
              icon: Symbols.photo_camera_rounded,
              enabled: true,
              busy: false,
              onTap: _scan,
              background: scheme.surfaceContainerHighest,
              foreground: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: FrostedSpacing.sp2),
            Expanded(child: _field(draft, showContext)),
            const SizedBox(width: FrostedSpacing.sp2),
            _RoundButton(
              icon: _sentFlashing
                  ? Symbols.check_rounded
                  : Symbols.arrow_upward_rounded,
              enabled: _sentFlashing || draft.isSubmittable,
              busy: _submitting,
              onTap: _sentFlashing ? _keepTyping : _submit,
              background: _categoryAccent(draft) ?? scheme.primary,
              foreground: _accentForeground(draft, scheme),
            ),
          ],
        ),
        AnimatedSize(
          duration: motion.duration,
          curve: motion.curve,
          alignment: Alignment.topCenter,
          child: showContext
              ? Padding(
                  padding: const EdgeInsets.only(top: FrostedSpacing.sp1),
                  child: QuickAddAccountLine(onNoAccount: widget.onNoAccount),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _field(QuickAddDraft draft, bool showContext) {
    final hint = widget.hint;
    if (hint == null) {
      return _fieldWithHint(draft, showContext, QuickAddBar.staticHint);
    }

    return ValueListenableBuilder<String>(
      valueListenable: hint,
      builder: (context, typed, _) => _fieldWithHint(
        draft,
        showContext,
        typed.isEmpty ? QuickAddBar.staticHint : typed,
      ),
    );
  }

  Widget _fieldWithHint(QuickAddDraft draft, bool showContext, String hint) {
    final usesRemote = ref.watch(quickAddUsesRemoteProvider);

    return QuickAddThinkingBorder(
      thinking: !draft.isEmpty && draft.isStale,
      child: FrostedTextField(
        controller: _controller,
        focusNode: _focusNode,
        leadingIcon: usesRemote
            ? Symbols.cloud_rounded
            : Symbols.auto_awesome_rounded,
        trailingIcon: showContext ? Symbols.close_rounded : null,
        onTrailingTap: _cancel,
        hintText: hint,
        textInputAction: TextInputAction.send,
        onChanged: _onChanged,
        onSubmitted: (_) => _submit(),
        onEditingComplete: _keepTyping,
      ),
    );
  }

  /// Once the model stands behind a category, its colour takes the send
  /// button : the tap records *that* transaction, not a generic submit.
  Color? _categoryAccent(QuickAddDraft draft) {
    final slug = draft.categorySlug;
    if (slug == null || draft.isStale || draft.isCategoryUncertain) {
      return null;
    }

    final display = ref
        .watch(categoryDisplayResolverProvider)
        .value
        ?.resolve(slug);
    if (display == null) return null;
    return Color(display.color);
  }

  Color _accentForeground(QuickAddDraft draft, ColorScheme scheme) {
    final accent = _categoryAccent(draft);
    if (accent == null) return scheme.onPrimary;
    return ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : const Color(0xFF1C1B1F);
  }

}

class _RoundButton extends StatelessWidget {
  static const double _size = 44;

  static const double _spinnerSize = 18;
  static const double _spinnerStroke = 2;

  final IconData icon;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  const _RoundButton({
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
