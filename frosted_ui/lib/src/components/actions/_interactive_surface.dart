import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InteractionStates {
  const InteractionStates({
    required this.hovered,
    required this.focused,
    required this.pressed,
    required this.enabled,
    required this.pressOrigin,
    required this.ripple,
  });

  final bool hovered;
  final bool focused;
  final bool pressed;
  final bool enabled;

  /// Where the last press landed, in the surface's own coordinates. Null
  /// until the surface has been touched, and for keyboard activation, which
  /// has no point to spread from.
  final Offset? pressOrigin;

  /// Drives the ink a press throws off — hand it, with [pressOrigin], to a
  /// [PressRipple] placed above the surface but below its content.
  final Animation<double> ripple;

  /// The state of a surface that carries no interaction at all, for
  /// components that share one builder between a tappable and a plain form.
  static const InteractionStates inert = InteractionStates(
    hovered: false,
    focused: false,
    pressed: false,
    enabled: true,
    pressOrigin: null,
    ripple: kAlwaysDismissedAnimation,
  );
}

typedef InteractiveSurfaceBuilder =
    Widget Function(BuildContext context, InteractionStates states);

class InteractiveSurface extends StatefulWidget {
  const InteractiveSurface({
    required this.onTap,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
    this.focusable = true,
    this.semanticsButton = true,
    this.semanticsLabel,
    this.semanticsSelected,
    super.key,
  });

  final VoidCallback? onTap;
  final InteractiveSurfaceBuilder builder;
  final MouseCursor cursor;
  final bool focusable;
  final bool semanticsButton;
  final String? semanticsLabel;
  final bool? semanticsSelected;

  @override
  State<InteractiveSurface> createState() => _InteractiveSurfaceState();
}

class _InteractiveSurfaceState extends State<InteractiveSurface>
    with SingleTickerProviderStateMixin {
  /// A tap is routinely shorter than the press transition, so releasing on
  /// tap-up reverses the morph before it has travelled far enough to read —
  /// on a text button, whose resting surface is transparent, that leaves the
  /// press invisible altogether. Holding the state for this long gives the
  /// transition room to land before it comes back.
  static const Duration _minPressDuration = Duration(milliseconds: 160);

  /// The ripple outlives the press it came from: it keeps spreading after the
  /// finger is up, which is what reads as a reaction rather than a state.
  static const Duration _rippleDuration = Duration(milliseconds: 450);

  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  bool _releasePending = false;
  Timer? _holdTimer;
  Offset? _pressOrigin;

  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: _rippleDuration,
  );

  bool get _enabled => widget.onTap != null;

  void _press(Offset origin) {
    _holdTimer?.cancel();
    _releasePending = false;
    _holdTimer = Timer(_minPressDuration, _onHoldElapsed);
    setState(() {
      _pressed = true;
      _pressOrigin = origin;
    });
    _ripple.forward(from: 0);
  }

  void _onHoldElapsed() {
    _holdTimer = null;
    if (_releasePending) _release();
  }

  void _requestRelease() {
    if (_holdTimer != null) {
      _releasePending = true;
      return;
    }
    _release();
  }

  void _release() {
    _releasePending = false;
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _ripple.dispose();
    super.dispose();
  }

  static final Map<Type, Action<Intent>> _emptyActions =
      <Type, Action<Intent>>{};

  Map<Type, Action<Intent>> _actions() {
    if (!_enabled) return _emptyActions;
    return <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          widget.onTap?.call();
          return null;
        },
      ),
      ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
        onInvoke: (_) {
          widget.onTap?.call();
          return null;
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final InteractionStates states = InteractionStates(
      hovered: _enabled && _hovered,
      focused: _enabled && _focused,
      pressed: _enabled && _pressed,
      enabled: _enabled,
      pressOrigin: _pressOrigin,
      ripple: _ripple,
    );

    Widget child = widget.builder(context, states);

    // The press reads through the state layer and the shape morph the builder
    // already draws, so the surface needs no ink of its own. Handling the tap
    // here — rather than in an overlay stacked above the content — leaves any
    // interactive child (a trailing icon button, say) free to win the gesture
    // arena on its own.
    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _enabled ? widget.onTap : null,
      onTapDown: _enabled
          ? (TapDownDetails details) => _press(details.localPosition)
          : null,
      onTapUp: _enabled ? (TapUpDetails _) => _requestRelease() : null,
      onTapCancel: _enabled ? _requestRelease : null,
      child: child,
    );

    child = FocusableActionDetector(
      enabled: _enabled,
      mouseCursor: _enabled ? widget.cursor : SystemMouseCursors.basic,
      onShowFocusHighlight: widget.focusable
          ? (bool showing) {
              if (showing != _focused) {
                setState(() => _focused = showing);
              }
            }
          : null,
      onShowHoverHighlight: (bool showing) {
        if (showing != _hovered) {
          setState(() => _hovered = showing);
        }
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: _actions(),
      child: child,
    );

    child = Semantics(
      button: widget.semanticsButton,
      enabled: _enabled,
      label: widget.semanticsLabel,
      selected: widget.semanticsSelected,
      child: child,
    );

    return child;
  }
}
