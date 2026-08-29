import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/widgets/capture_anchor.dart';
import 'package:mybudget/ui/capture/widgets/category_wash.dart';
import 'package:mybudget/ui/capture/widgets/journal_view.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_hint_typer.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/screens/expense_form_screen.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_bar.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_no_account_dialog.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/scan/receipt_scan_launcher.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';

/// The page the app opens on : one figure, the day's journal, and the input
/// under the thumb. Everything else is a consequence of what gets typed here.
class CaptureScreen extends ConsumerStatefulWidget {
  /// Fallback used before the dock has been measured, so the first frame does
  /// not hide the newest line behind the glass.
  static const double estimatedDockHeight = 108;

  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final QuickAddHintTyper _hint = QuickAddHintTyper();
  double _dockHeight = CaptureScreen.estimatedDockHeight;
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

  void _onDockMeasured(double height) {
    if ((height - _dockHeight).abs() < 0.5) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _dockHeight = height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(todayJournalProvider);
    _syncHint(entries.isEmpty);

    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final dockBottom = keyboardUp
        ? FrostedSpacing.sp3
        : mainFlowBottomInset(context);

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          const Positioned.fill(child: CategoryWash()),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedSpacing.sp5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CaptureAnchor(
                  remaining: ref.watch(remainingThisMonthProvider),
                  monthlyRevenues: ref.watch(currentMonthRevenuesProvider),
                  onTap: () =>
                      ref.read(homeNavigationProvider.notifier).openStats(),
                ),
                Expanded(
                  child: JournalView(bottomInset: _dockHeight + dockBottom),
                ),
              ],
            ),
          ),
          Positioned(
            left: FrostedSpacing.sp5,
            right: FrostedSpacing.sp5,
            bottom: dockBottom,
            child: _MeasureHeight(
              onMeasured: _onDockMeasured,
              child: _Dock(
                hint: _hint,
                focused: _focused,
                onFocusChanged: _onFocusChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The input and, above it, the line it is about to become.
class _Dock extends ConsumerWidget {
  final QuickAddHintTyper hint;
  final bool focused;
  final ValueChanged<bool> onFocusChanged;

  const _Dock({
    required this.hint,
    required this.focused,
    required this.onFocusChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(quickAddEnabledProvider)) {
      return const _ManualDock();
    }

    return QuickAddBar(
      focused: focused,
      hint: hint,
      onFocusChanged: onFocusChanged,
      onNoAccount: () => showQuickAddNoAccountDialog(context),
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

/// Reports the height of its child so the journal can leave exactly that much
/// room under its last line, and no more.
class _MeasureHeight extends StatefulWidget {
  final ValueChanged<double> onMeasured;
  final Widget child;

  const _MeasureHeight({required this.onMeasured, required this.child});

  @override
  State<_MeasureHeight> createState() => _MeasureHeightState();
}

class _MeasureHeightState extends State<_MeasureHeight> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) widget.onMeasured(box.size.height);
    });

    return KeyedSubtree(key: _key, child: widget.child);
  }
}
