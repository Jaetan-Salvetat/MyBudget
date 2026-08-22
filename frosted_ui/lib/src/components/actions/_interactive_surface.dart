import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InteractionStates {
  const InteractionStates({
    required this.hovered,
    required this.focused,
    required this.pressed,
    required this.enabled,
  });

  final bool hovered;
  final bool focused;
  final bool pressed;
  final bool enabled;
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
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
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
      onTapDown: _enabled ? (TapDownDetails _) => _setPressed(true) : null,
      onTapUp: _enabled ? (TapUpDetails _) => _setPressed(false) : null,
      onTapCancel: _enabled ? () => _setPressed(false) : null,
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
