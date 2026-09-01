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
import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';

class CaptureDock extends ConsumerStatefulWidget {
  static const double clearance = FrostedSpacing.sp3;

  static const double padding = FrostedSpacing.sp4;

  static const double radius = FrostedRadius.xl;

  static const FrostedGlassLevel level = FrostedGlassLevel.thick;

  static const FrostedGlassElevation elevation = FrostedGlassElevation.resting;

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
      child: FrostedGlass(
        level: CaptureDock.level,
        elevation: CaptureDock.elevation,
        borderRadius: BorderRadius.circular(CaptureDock.radius),
        padding: const EdgeInsets.all(CaptureDock.padding),
        child: ref.watch(quickAddEnabledProvider)
            ? QuickAddBar(
                focused: _focused,
                hint: _hint,
                onFocusChanged: _onFocusChanged,
                onNoAccount: () => showQuickAddNoAccountDialog(context),
              )
            : const _ManualDock(),
      ),
    );
  }
}

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
        if (ref.watch(receiptScanAvailableProvider)) ...[
          const SizedBox(width: FrostedSpacing.sp2),
          FrostedIconButton.tonal(
            icon: Symbols.photo_camera_rounded,
            onPressed: () => showReceiptScanSourceSheet(context),
          ),
        ],
      ],
    );
  }
}
