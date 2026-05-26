import 'dart:ui';

import 'package:flutter/material.dart';

/// A [Scaffold] wrapper that builds its own drawer overlay so the scrim
/// (blur + light voile) sits **above** the app bar instead of underneath it.
///
/// All standard Scaffold knobs are exposed; in addition, a custom drawer
/// animation is managed internally. Reach for `FrostedScaffold.of(context)`
/// to open or close the drawer from descendants.
///
/// `extendBody` and `extendBodyBehindAppBar` default to `true` — every
/// Frosted UI chrome floats above content.
class FrostedScaffold extends StatefulWidget {
  const FrostedScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.extendBody = true,
    this.extendBodyBehindAppBar = true,
    this.resizeToAvoidBottomInset = true,
    this.drawerWidth = 296,
    this.scrimBlurSigma = 24,
    this.scrimColor = const Color(0x33000000),
    this.onDrawerChanged,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  /// Width of the drawer panel. The drawer widget you pass should match (or
  /// be constrained by) this value.
  final double drawerWidth;

  /// Maximum blur sigma applied to the scrim when the drawer is fully open.
  final double scrimBlurSigma;

  /// Color of the scrim voile painted over the blurred backdrop when the
  /// drawer is fully open. The actual opacity is interpolated by the drawer
  /// animation progress.
  final Color scrimColor;

  /// Fires with `true` when the drawer finishes opening, `false` when it
  /// finishes closing.
  final ValueChanged<bool>? onDrawerChanged;

  /// Resolve the nearest [FrostedScaffoldState] from a descendant.
  ///
  /// Throws when no [FrostedScaffold] is found in the ancestor chain.
  static FrostedScaffoldState of(BuildContext context) {
    final FrostedScaffoldState? state =
        context.findAncestorStateOfType<FrostedScaffoldState>();
    if (state == null) {
      throw FlutterError(
        'FrostedScaffold.of() called with a context that does not contain a FrostedScaffold.',
      );
    }
    return state;
  }

  @override
  State<FrostedScaffold> createState() => FrostedScaffoldState();
}

class FrostedScaffoldState extends State<FrostedScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _lastNotifiedOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _controller.addStatusListener(_onAnimationStatus);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_lastNotifiedOpen) {
      _lastNotifiedOpen = true;
      widget.onDrawerChanged?.call(true);
    } else if (status == AnimationStatus.dismissed && _lastNotifiedOpen) {
      _lastNotifiedOpen = false;
      widget.onDrawerChanged?.call(false);
    }
  }

  /// Slide the drawer in.
  void openDrawer() {
    if (widget.drawer == null) return;
    _controller.forward();
  }

  /// Slide the drawer out.
  void closeDrawer() {
    _controller.reverse();
  }

  /// Open if closed, close if open.
  void toggleDrawer() {
    if (_controller.value >= 0.5) {
      closeDrawer();
    } else {
      openDrawer();
    }
  }

  /// True once the drawer animation is past halfway.
  bool get isDrawerOpen => _controller.value > 0.5;

  @override
  Widget build(BuildContext context) {
    final Scaffold scaffold = Scaffold(
      appBar: widget.appBar,
      body: widget.body,
      bottomNavigationBar: widget.bottomNavigationBar,
      endDrawer: widget.endDrawer,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      backgroundColor: widget.backgroundColor,
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
    );

    if (widget.drawer == null) {
      return scaffold;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final double t = _controller.value;
        final double slide = widget.drawerWidth * t;

        return Stack(
          children: <Widget>[
            Positioned.fill(child: scaffold),
            if (t > 0)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: closeDrawer,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: widget.scrimBlurSigma * t,
                        sigmaY: widget.scrimBlurSigma * t,
                      ),
                      child: ColoredBox(
                        color: widget.scrimColor.withValues(
                          alpha: widget.scrimColor.a * t,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              bottom: 0,
              left: -widget.drawerWidth + slide,
              width: widget.drawerWidth,
              child: widget.drawer!,
            ),
          ],
        );
      },
    );
  }
}
