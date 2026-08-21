import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';

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

typedef InteractiveSurfaceBuilder = Widget Function(
  BuildContext context,
  InteractionStates states,
);

class InteractiveSurface extends StatefulWidget {
  const InteractiveSurface({
    required this.onTap,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
    this.focusable = true,
    this.semanticsButton = true,
    this.semanticsLabel,
    this.semanticsSelected,
    this.shape,
    super.key,
  });

  final VoidCallback? onTap;
  final InteractiveSurfaceBuilder builder;
  final MouseCursor cursor;
  final bool focusable;
  final bool semanticsButton;
  final String? semanticsLabel;
  final bool? semanticsSelected;

  /// Resolves the surface shape for a given interaction state — the single
  /// source of truth for both the fill (via [builder]) and the ripple clip.
  /// The clip animates as the resolved radius changes, so the ink always
  /// tracks the container's shape morph. Null → a rectangular clip.
  final BorderRadius Function(InteractionStates states)? shape;

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

    // Ripple painted above the surface fill, clipped to the shape. State
    // layers (hover/focus/press tint) stay on the builder; the InkWell only
    // contributes the ink splash. The clip morphs with the press so the ink
    // tracks the container's shape change instead of lagging behind it.
    final FrostedMotion motion = context.frostedTokens.motion.snappy;
    final BorderRadius targetRadius =
        widget.shape?.call(states) ?? BorderRadius.zero;

    // The InkWell paints into a Material whose own shape clips the splash to
    // the rounded corners — so the ink never bleeds into a neighbour. Only
    // this ink layer is clipped; the builder's content (and any shadow it
    // draws, e.g. the FAB) stays unclipped. The shape morphs with the press.
    child = Stack(
      children: <Widget>[
        child,
        Positioned.fill(
          child: TweenAnimationBuilder<BorderRadius?>(
            duration: motion.duration,
            curve: motion.curve,
            tween: Tween<BorderRadius?>(end: targetRadius),
            builder: (BuildContext context, BorderRadius? radius, Widget? _) {
              return Material(
                type: MaterialType.transparency,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: radius ?? targetRadius,
                ),
                child: InkWell(
                  onTap: _enabled ? widget.onTap : null,
                  onTapDown: _enabled
                      ? (TapDownDetails _) => _setPressed(true)
                      : null,
                  onTapUp:
                      _enabled ? (TapUpDetails _) => _setPressed(false) : null,
                  onTapCancel: _enabled ? () => _setPressed(false) : null,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
              );
            },
          ),
        ),
      ],
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
