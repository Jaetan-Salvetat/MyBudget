import 'package:material_ui/material_ui.dart';

import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';

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
    this.scrimLevel = FrostedGlassLevel.regular,
    this.scrimTone = FrostedGlassTone.dark,
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

  final double drawerWidth;

  final FrostedGlassLevel scrimLevel;

  final FrostedGlassTone scrimTone;

  final ValueChanged<bool>? onDrawerChanged;

  static FrostedScaffoldState of(BuildContext context) {
    final FrostedScaffoldState? state = context
        .findAncestorStateOfType<FrostedScaffoldState>();
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

  void openDrawer() {
    if (widget.drawer == null) return;
    _controller.forward();
  }

  void closeDrawer() {
    _controller.reverse();
  }

  void toggleDrawer() {
    if (_controller.value >= 0.5) {
      closeDrawer();
    } else {
      openDrawer();
    }
  }

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
                  child: FrostedGlass(
                    level: widget.scrimLevel,
                    tone: widget.scrimTone,
                    elevation: FrostedGlassElevation.none,
                    borderRadius: BorderRadius.zero,
                    borderEdges: FrostedGlassEdge.none,
                    animation: _controller,
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
