import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/quick_add_landing.dart';
import 'package:mybudget/ui/capture/widgets/capture_anchor.dart';
import 'package:mybudget/ui/capture/widgets/capture_dock.dart';
import 'package:mybudget/ui/capture/widgets/journal_view.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';

/// The page the app opens on : one figure, the day's journal, and the input
/// under the thumb. Everything else is a consequence of what gets typed here.
///
/// Le dock flotte au-dessus de la barre du bas au lieu d'y rentrer : des deux
/// chromes de ce bord, celui qui porte l'action est celui qui doit flotter, et
/// la barre ne fait que dire où l'on est.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  /// L'atterrissage appartient à l'écran qui porte à la fois le champ et le
  /// journal : la page ne fait que l'écouter.
  QuickAddLandingController? _landing;

  /// Ce que le dock occupe en bas de la page, mesuré : il grandit avec le
  /// brouillon, et le journal se replie d'autant.
  double _dockHeight = 0;

  /// La figure du mois pendant qu'une transaction se pose : elle garde ce
  /// qu'elle disait avant l'envoi et n'encaisse qu'une fois le créneau ouvert.
  double? _heldFigure;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final QuickAddLandingController? landing = QuickAddLanding.controllerOf(
      context,
    );
    if (identical(landing, _landing)) return;

    _landing?.removeListener(_onLanding);
    _landing = landing?..addListener(_onLanding);
  }

  @override
  void dispose() {
    _landing?.removeListener(_onLanding);
    super.dispose();
  }

  void _onLanding() {
    if (!mounted) return;

    final held = _landing!.holdsTheFigure
        ? (_heldFigure ?? ref.read(remainingThisMonthProvider))
        : null;
    if (held == _heldFigure) return;

    setState(() => _heldFigure = held);
  }

  void _onDockHeight(double height) {
    if (!mounted || height == _dockHeight) return;
    setState(() => _dockHeight = height);
  }

  @override
  Widget build(BuildContext context) {
    // Le scaffold rend l'empreinte exacte de la barre — safe area comprise —
    // dans le padding bas du body, et la reprend quand le clavier la replie :
    // le dock n'a qu'à se poser dessus.
    final barFootprint = MediaQuery.paddingOf(context).bottom;
    final remaining = ref.watch(remainingThisMonthProvider);

    return SafeArea(
      bottom: false,
      // Le journal descend jusqu'au bas de l'écran et passe sous le dock puis
      // sous la barre, qui le recouvrent : sans rien derrière eux, le verre
      // n'aurait rien à flouter et la page se couperait net au-dessus du champ.
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
                Expanded(
                  child: JournalView(bottomInset: barFootprint + _dockHeight),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: barFootprint,
            child: _MeasuredHeight(
              onHeight: _onDockHeight,
              child: const CaptureDock(),
            ),
          ),
        ],
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
