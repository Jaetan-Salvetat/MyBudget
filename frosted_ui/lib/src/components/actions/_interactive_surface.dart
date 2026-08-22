import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '_press_ink.dart';

class InteractionStates {
  const InteractionStates({
    required this.hovered,
    required this.focused,
    required this.pressed,
    required this.enabled,
    required this.pressInk,
  });

  final bool hovered;
  final bool focused;
  final bool pressed;
  final bool enabled;

  /// The press ink of this surface, or null when nothing is interactive
  /// here. Place it with [ink]; the splash itself comes from the theme.
  final PressInk? pressInk;

  /// The state of a surface that carries no interaction at all, for
  /// components that share one builder between a tappable and a plain form.
  static const InteractionStates inert = InteractionStates(
    hovered: false,
    focused: false,
    pressed: false,
    enabled: true,
    pressInk: null,
  );

  /// Lays the press ink under [child] — above the surface the builder drew,
  /// below the label it carries. The ink takes its colour from the ambient
  /// [ThemeData.splashColor]; pass the surface's [borderRadius] so it stops
  /// at its corners.
  Widget ink(Widget child, {BorderRadius? borderRadius}) {
    final PressInk? pressInk = this.pressInk;
    if (pressInk == null) return child;
    return PressInkHost(
      ink: pressInk,
      borderRadius: borderRadius,
      child: child,
    );
  }
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

class _InteractiveSurfaceState extends State<InteractiveSurface> {
  /// A tap is routinely shorter than the press transition, so releasing on
  /// tap-up reverses the morph before it has travelled far enough to read —
  /// on a text button, whose resting surface is transparent, that leaves the
  /// press invisible altogether. Holding the state for this long gives the
  /// transition room to land before it comes back.
  static const Duration _minPressDuration = Duration(milliseconds: 160);

  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  bool _releasePending = false;
  Timer? _holdTimer;

  final PressInk _ink = PressInk();

  bool get _enabled => widget.onTap != null;

  void _press(Offset globalPosition) {
    _holdTimer?.cancel();
    _releasePending = false;
    _holdTimer = Timer(_minPressDuration, _onHoldElapsed);
    setState(() => _pressed = true);
    _ink.start(globalPosition: globalPosition);
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

  /// A press that never became a tap — the pointer scrolled away, or a nested
  /// target took the gesture — takes its ink with it rather than playing out
  /// a reaction to something that did not happen.
  void _abort() {
    _ink.cancel();
    _requestRelease();
  }

  void _release() {
    _releasePending = false;
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  static final Map<Type, Action<Intent>> _emptyActions =
      <Type, Action<Intent>>{};

  /// Keyboard activation has no point to spread from, so its ink starts at
  /// the middle of the surface and is confirmed at once — there is no press
  /// to hold it open.
  Object? _activate() {
    _ink.start();
    _ink.confirm();
    widget.onTap?.call();
    return null;
  }

  Map<Type, Action<Intent>> _actions() {
    if (!_enabled) return _emptyActions;
    return <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) => _activate(),
      ),
      ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
        onInvoke: (_) => _activate(),
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
      pressInk: _ink,
    );

    Widget child = widget.builder(context, states);

    // The ink itself is the builder's to place — only it knows which layer
    // sits between its surface and its content — so this level only reports
    // the press to [InteractionStates.pressInk]. Handling the tap here,
    // rather than in an overlay stacked above the content, leaves any child (a
    // trailing icon button, say) free to win the gesture arena on its own.
    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _enabled ? widget.onTap : null,
      onTapDown: _enabled
          ? (TapDownDetails details) => _press(details.globalPosition)
          : null,
      onTapUp: _enabled
          ? (TapUpDetails _) {
              _ink.confirm();
              _requestRelease();
            }
          : null,
      onTapCancel: _enabled ? _abort : null,
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
