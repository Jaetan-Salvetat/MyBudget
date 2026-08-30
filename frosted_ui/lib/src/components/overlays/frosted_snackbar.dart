import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../actions/frosted_button.dart';

class FrostedSnackbar {
  const FrostedSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    double bottomInset = 0,
  }) {
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    final ThemeData theme = Theme.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext context) => Theme(
        data: theme,
        child: _SnackbarHost(
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
          duration: duration,
          bottomInset: bottomInset,
          onDismissed: () => entry.remove(),
        ),
      ),
    );
    overlay.insert(entry);
  }
}

class _SnackbarHost extends StatefulWidget {
  const _SnackbarHost({
    required this.message,
    required this.duration,
    required this.bottomInset,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final double bottomInset;
  final VoidCallback onDismissed;

  @override
  State<_SnackbarHost> createState() => _SnackbarHostState();
}

class _SnackbarHostState extends State<_SnackbarHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: const Cubic(0.32, 0.72, 0, 1),
    reverseCurve: Curves.easeIn,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Positioned(
      left: FrostedSpacing.sp4,
      right: FrostedSpacing.sp4,
      bottom: FrostedSpacing.sp4 + bottomSafe + widget.bottomInset,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(_curve),
          child: SafeArea(
            top: false,
            child: Material(
              type: MaterialType.transparency,
              child: FrostedGlass(
                level: FrostedGlassLevel.thick,
                elevation: FrostedGlassElevation.lifted,
                borderRadius: BorderRadius.circular(FrostedRadius.md),
                padding: EdgeInsets.only(
                  left: FrostedSpacing.sp4,
                  right: widget.actionLabel != null
                      ? FrostedSpacing.sp2
                      : FrostedSpacing.sp4,
                  top: FrostedSpacing.sp2,
                  bottom: FrostedSpacing.sp2,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: FrostedSpacing.sp2,
                        ),
                        child: Text(
                          widget.message,
                          style: FrostedTypeScale.bodyMedium.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                    if (widget.actionLabel != null) ...<Widget>[
                      const SizedBox(width: FrostedSpacing.sp2),
                      FrostedButton.text(
                        label: widget.actionLabel!,
                        onPressed: () {
                          widget.onAction?.call();
                          _dismiss();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
