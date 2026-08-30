import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_shape.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import 'frosted_fab.dart';

@immutable
class FrostedFabAction {
  const FrostedFabAction({
    required this.icon,
    required this.onPressed,
    this.label,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
}

class FrostedExpandableFab extends StatefulWidget {
  const FrostedExpandableFab({
    required this.actions,
    this.icon = Icons.add,
    this.closeIcon = Icons.close,
    this.tooltip,
    super.key,
  });

  final List<FrostedFabAction> actions;

  final IconData icon;

  final IconData closeIcon;

  final String? tooltip;

  @override
  State<FrostedExpandableFab> createState() => FrostedExpandableFabState();
}

class FrostedExpandableFabState extends State<FrostedExpandableFab>
    with SingleTickerProviderStateMixin {
  static const double _triggerBox = 56;
  static const double _actionBox = 40;

  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  bool get isOpen => _portal.isShowing;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void open() {
    if (isOpen) return;
    _portal.show();
    _controller.forward();
  }

  void close() {
    if (!isOpen) return;
    _controller.reverse().whenComplete(() {
      if (mounted) _portal.hide();
    });
  }

  void toggle() => isOpen ? close() : open();

  void _runAction(FrostedFabAction action) {
    close();
    action.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: _buildFanOut,
      child: CompositedTransformTarget(
        link: _link,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? _) {
            final bool deployed = _controller.value == 1;
            return Transform.rotate(
              angle: deployed ? 0 : _controller.value * math.pi / 4,
              child: FrostedFab.regular(
                icon: deployed ? widget.closeIcon : widget.icon,
                tooltip: widget.tooltip,
                onPressed: toggle,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFanOut(BuildContext context) {
    final FrostedMotion motion = context.frostedTokens.motion.fluid;
    final CurvedAnimation curve = CurvedAnimation(
      parent: _controller,
      curve: motion.curve,
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: close,
            child: FrostedGlass(
              level: FrostedGlassLevel.regular,
              tone: FrostedGlassTone.dark,
              elevation: FrostedGlassElevation.none,
              borderRadius: BorderRadius.zero,
              animation: curve,
            ),
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.bottomRight,
          offset: const Offset(
            -(_triggerBox - _actionBox) / 2,
            -FrostedSpacing.sp3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int i = 0; i < widget.actions.length; i++)
                _FanOutAction(
                  action: widget.actions[i],
                  onPressed: () => _runAction(widget.actions[i]),
                  animation: _staggered(i),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Animation<double> _staggered(int index) {
    final int count = widget.actions.length;
    final int rank = count - 1 - index;
    final double start = rank / count;
    final double end = (rank + 1) / count;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
  }
}

class _FanOutAction extends StatelessWidget {
  const _FanOutAction({
    required this.action,
    required this.onPressed,
    required this.animation,
  });

  final FrostedFabAction action;
  final VoidCallback onPressed;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value.clamp(0.0, 1.0);
        if (t == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: animation.value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: FrostedSpacing.sp3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (action.label != null) ...<Widget>[
              _ActionLabel(label: action.label!),
              const SizedBox(width: FrostedSpacing.sp3),
            ],
            FrostedFab.small(
              icon: action.icon,
              tonal: true,
              shape: FrostedShape.pill,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(FrostedRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.sp3,
          vertical: FrostedSpacing.sp1 + 2,
        ),
        child: Text(
          label,
          style: FrostedTypeScale.labelLarge.copyWith(color: cs.onSurface),
        ),
      ),
    );
  }
}
