import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_hint_typer.dart';
import 'package:mybudget/ui/expenses/screens/expense_form_screen.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_bar.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_no_account_dialog.dart';
import 'package:mybudget/ui/scan/receipt_scan_launcher.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';

/// Le champ de saisie, porté par la barre du bas.
///
/// Il rentre dans le verre de la barre au lieu de flotter dessus : deux
/// chromes bord à bord se lisent comme un seul objet raté, et le journal
/// passait à nu dans la fente entre les deux.
class CaptureDock extends ConsumerStatefulWidget {
  /// Air que le dock garde de chaque côté : au-dessus la dernière ligne du
  /// journal, en dessous la barre. Il flotte, il ne se pose sur rien.
  static const double clearance = FrostedSpacing.sp3;

  const CaptureDock({super.key});

  @override
  ConsumerState<CaptureDock> createState() => _CaptureDockState();
}

class _CaptureDockState extends ConsumerState<CaptureDock> {
  final QuickAddHintTyper _hint = QuickAddHintTyper();
  bool _hintStarted = false;
  bool _focused = false;

  @override
  void dispose() {
    _hint.dispose();
    super.dispose();
  }

  void _onFocusChanged(bool focused) {
    if (focused) _hint.stop();
    if (focused == _focused) return;
    setState(() => _focused = focused);
  }

  /// The hint only ever runs on a day with nothing on it : once a line is
  /// there, the page already says what it can do.
  void _syncHint(bool dayIsEmpty) {
    if (!dayIsEmpty) {
      _hint.stop();
      return;
    }
    if (_hintStarted) return;

    _hintStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _hint.freeze();
    } else {
      _hint.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncHint(ref.watch(todayJournalProvider).isEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kMainFlowGutter,
        vertical: CaptureDock.clearance,
      ),
      child: ref.watch(quickAddEnabledProvider)
          ? QuickAddBar(
              focused: _focused,
              hint: _hint,
              onFocusChanged: _onFocusChanged,
              onNoAccount: () => showQuickAddNoAccountDialog(context),
            )
          : const _ManualDock(),
    );
  }
}

/// Quick-add turned off in the settings : the page keeps its two gestures,
/// the scan and the form, rather than becoming a dead end.
class _ManualDock extends ConsumerWidget {
  const _ManualDock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: FrostedButton.filled(
            label: 'Ajouter une dépense',
            icon: Symbols.add_rounded,
            onPressed: () => ExpenseFormScreen.push(
              context: context,
              accounts: ref.read(accountProvider).value ?? const [],
            ),
          ),
        ),
        const SizedBox(width: FrostedSpacing.sp2),
        FrostedIconButton.tonal(
          icon: Symbols.photo_camera_rounded,
          onPressed: () => showReceiptScanSourceSheet(context),
        ),
      ],
    );
  }
}
