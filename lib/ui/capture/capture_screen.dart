import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/capture/capture_provider.dart';
import 'package:mybudget/ui/capture/quick_add_landing.dart';
import 'package:mybudget/ui/capture/widgets/capture_anchor.dart';
import 'package:mybudget/ui/capture/widgets/capture_dock.dart';
import 'package:mybudget/ui/capture/widgets/journal_view.dart';
import 'package:mybudget/ui/home/home_navigation_provider.dart';
import 'package:mybudget/ui/revenues/revenue_queries.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  QuickAddLandingController? _landing;

  double _dockHeight = 0;

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
    final barFootprint = MediaQuery.paddingOf(context).bottom;
    final remaining = ref.watch(remainingThisMonthProvider);

    return SafeArea(
      bottom: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kMainFlowGutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CaptureAnchor(
                  now: ref.read(clockProvider)(),
                  remaining: _heldFigure ?? remaining,
                  monthlyRevenues: ref.watch(currentMonthRevenuesProvider),
                  onTap: () =>
                      ref.read(homeNavigationProvider.notifier).openStats(),
                  onSettings: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
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

class _MeasuredHeight extends SingleChildRenderObjectWidget {
  const _MeasuredHeight({required this.onHeight, required Widget super.child});
  final ValueChanged<double> onHeight;

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
  _RenderMeasuredHeight(this.onHeight);
  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (_reported == size.height) return;

    _reported = size.height;
    WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(size.height));
  }
}
