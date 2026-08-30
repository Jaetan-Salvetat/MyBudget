import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/models/quick_add_draft_model.dart';
import 'package:mybudget/ui/capture/quick_add_landing.dart';
import 'package:mybudget/ui/quick_add/quick_add_account_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_focus_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_recent_submissions_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_account_line.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_preview.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_send_action.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_thinking_border.dart';
import 'package:mybudget/ui/scan/receipt_scan_launcher.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';

/// Là où le champ commence, une fois le bouton de scan posé : sa boîte, et
/// l'air que le composant porte de chaque côté. La ligne de compte s'y
/// aligne — elle parle du champ, pas du bord de la rangée.
final double _kFieldOffset =
    FrostedIconButtonSize.medium.box + FrostedSpacing.sp1 * 2;

/// The one place a transaction gets typed. Reads the text as it comes,
/// creates on submit, and keeps the keyboard up : entering the day's expenses
/// is a rafale, not one trip per line. The way back sits on the journal line
/// the transaction just became.
class QuickAddBar extends ConsumerStatefulWidget {
  /// Un seul exemple : une liste d'exemples ne tient pas dans le champ et
  /// finit tronquée par des points de suspension.
  static const String staticHint = 'courses carrefour 42';

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

  /// Vider le champ n'est pas en sortir : le clavier reste, la frappe
  /// suivante part tout de suite.
  void _cancel() {
    _controller.clear();
    ref.read(quickAddProvider.notifier).reset();
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
            // Le second geste de la page, pas son action : l'accent revient à
            // l'envoi, et deux disques pleins de part et d'autre du champ
            // n'auraient dit lequel des deux la page attend.
            FrostedIconButton.tonal(
              icon: Symbols.photo_camera_rounded,
              shape: FrostedShape.pill,
              tooltip: 'Photographier le ticket',
              onPressed: _scan,
            ),
            Expanded(child: _field(draft)),
          ],
        ),
        AnimatedSize(
          duration: motion.duration,
          curve: motion.curve,
          alignment: Alignment.topCenter,
          child: showContext
              ? Padding(
                  // Alignée sur le champ, dont elle parle, pas sur le bord de
                  // la rangée.
                  padding: EdgeInsets.only(
                    left: _kFieldOffset,
                    top: FrostedSpacing.sp1,
                  ),
                  child: QuickAddAccountLine(onNoAccount: widget.onNoAccount),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  /// Ce que la poignée du champ propose à l'instant. L'attente et l'accusé
  /// passent devant le brouillon : le champ est déjà vide pour la frappe
  /// suivante, et l'envoi qui vient de partir a encore quelque chose à dire.
  QuickAddSendState _sendState(QuickAddDraft draft) {
    if (_submitting) return QuickAddSendState.sending;
    if (_sentFlashing) return QuickAddSendState.sent;

    return draft.isSubmittable
        ? QuickAddSendState.ready
        : QuickAddSendState.idle;
  }

  /// Les poignées du champ : la sortie tant qu'il y a quelque chose à vider,
  /// l'envoi dès que ce qui est écrit tient debout.
  ///
  /// Aucune sur un champ vide — ni la sortie, qui ne ferait rien, ni la place
  /// que l'envoi réserve : elle mangerait la largeur du texte pour rien.
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
    if (hint == null) return _fieldWithHint(draft, QuickAddBar.staticHint);

    return ValueListenableBuilder<String>(
      valueListenable: hint,
      builder: (context, typed, _) => _fieldWithHint(
        draft,
        typed.isEmpty ? QuickAddBar.staticHint : typed,
      ),
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
