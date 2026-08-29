import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/quick_add_landing.dart';
import 'package:mybudget/ui/capture/widgets/capture_anchor.dart';
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
import 'package:mybudget/ui/settings/settings_screen.dart';

/// The page the app opens on : one figure, the day's journal, and the input
/// under the thumb. Everything else is a consequence of what gets typed here.
///
/// Les trois se suivent dans une colonne : le dock prend sa place au lieu de
/// flotter au-dessus du journal, et le journal recule quand le brouillon
/// s'ouvre.
class CaptureScreen extends ConsumerStatefulWidget {
  /// Air entre la dernière ligne du journal et le dock.
  static const double dockClearance = FrostedSpacing.sp3;

  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final QuickAddHintTyper _hint = QuickAddHintTyper();
  final QuickAddLandingController _landing = QuickAddLandingController();
  bool _hintStarted = false;
  bool _focused = false;

  /// Ce que le dock occupe en bas de la page, mesuré : il grandit avec le
  /// brouillon, et le journal se replie d'autant.
  double _dockHeight = 0;

  /// La figure du mois pendant qu'une transaction se pose : elle garde ce
  /// qu'elle disait avant l'envoi et n'encaisse qu'une fois le créneau ouvert.
  double? _heldFigure;

  @override
  void initState() {
    super.initState();
    _landing.addListener(_onLanding);
  }

  @override
  void dispose() {
    _landing.removeListener(_onLanding);
    _landing.dispose();
    _hint.dispose();
    super.dispose();
  }

  void _onLanding() {
    if (!mounted) return;

    final held = _landing.holdsTheFigure
        ? (_heldFigure ?? ref.read(remainingThisMonthProvider))
        : null;
    if (held == _heldFigure) return;

    setState(() => _heldFigure = held);
  }

  void _onDockHeight(double height) {
    if (!mounted || height == _dockHeight) return;
    setState(() => _dockHeight = height);
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
    final entries = ref.watch(todayJournalProvider);
    _syncHint(entries.isEmpty);

    // Le scaffold met déjà sous le body la place exacte de la nav pill, et la
    // reprend quand le clavier la fait disparaître : le dock n'a qu'à se poser
    // dessus. Compter la pill une seconde fois laissait le champ flotter très
    // au-dessus d'elle, et loin du pouce.
    final dockBottom =
        MediaQuery.paddingOf(context).bottom + CaptureScreen.dockClearance;
    final remaining = ref.watch(remainingThisMonthProvider);

    return QuickAddLanding(
      notifier: _landing,
      child: SafeArea(
        bottom: false,
        // Le journal descend jusqu'au bas de l'écran et passe sous le dock,
        // qui le recouvre : sans rien derrière lui, le verre n'aurait rien à
        // flouter et la page se couperait net au-dessus du champ.
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kMainFlowGutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CaptureAnchor(
                    remaining: _heldFigure ?? remaining,
                    monthlyRevenues: ref.watch(currentMonthRevenuesProvider),
                    onTap: () =>
                        ref.read(homeNavigationProvider.notifier).openStats(),
                    onSettings: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  Expanded(child: JournalView(bottomInset: _dockHeight)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _MeasuredHeight(
                onHeight: _onDockHeight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    kMainFlowGutter,
                    CaptureScreen.dockClearance,
                    kMainFlowGutter,
                    dockBottom,
                  ),
                  child: _Dock(
                    hint: _hint,
                    focused: _focused,
                    onFocusChanged: _onFocusChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rend sa hauteur au reste de la page.
class _MeasuredHeight extends SingleChildRenderObjectWidget {
  final ValueChanged<double> onHeight;

  const _MeasuredHeight({required this.onHeight, required Widget super.child});

  @override
  _RenderMeasuredHeight createRenderObject(BuildContext context) =>
      _RenderMeasuredHeight(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasuredHeight renderObject,
  ) => renderObject.onHeight = onHeight;
}

class _RenderMeasuredHeight extends RenderProxyBox {
  ValueChanged<double> onHeight;
  double? _reported;

  _RenderMeasuredHeight(this.onHeight);

  @override
  void performLayout() {
    super.performLayout();
    if (_reported == size.height) return;

    _reported = size.height;
    // La mesure tombe pendant le layout : prévenir tout de suite relancerait
    // celui de la frame en cours.
    WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(size.height));
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
