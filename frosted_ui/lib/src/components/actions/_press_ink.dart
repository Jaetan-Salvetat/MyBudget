import 'dart:collection';

import 'package:flutter/material.dart';

/// The press ink of one interactive surface.
///
/// A surface reports its presses here and the [PressInkHost] planted in its
/// layer stack turns them into whichever splash the ambient theme prescribes.
/// The library paints no ink of its own, so a press inside it and a press on
/// a plain Material widget react the same way — by construction, not by a
/// hand-kept resemblance.
class PressInk {
  _PressInkHostState? _host;

  void _attach(_PressInkHostState host) => _host = host;

  void _detach(_PressInkHostState host) {
    if (identical(_host, host)) _host = null;
  }

  /// Starts a splash under [globalPosition] — or at the middle of the
  /// surface when the press carries no point, as keyboard activation does.
  void start({Offset? globalPosition}) => _host?.start(globalPosition);

  /// The press became a tap: let the splash play out.
  void confirm() => _host?.confirm();

  /// The press never became a tap — the pointer scrolled away, or a nested
  /// target took the gesture — so the ink goes back with it.
  void cancel() => _host?.cancel();
}

/// Carries the Material ink layer of a surface, between the surface it sits
/// on and the content above it, so a splash washes over the glass without
/// tinting the label.
class PressInkHost extends StatefulWidget {
  const PressInkHost({
    required this.ink,
    required this.child,
    this.borderRadius,
    super.key,
  });

  final PressInk ink;

  /// The corners the ink is confined to. Null keeps it to the plain
  /// rectangle the surface occupies.
  final BorderRadius? borderRadius;

  final Widget child;

  @override
  State<PressInkHost> createState() => _PressInkHostState();
}

class _PressInkHostState extends State<PressInkHost> {
  /// A context below the [Material] this host plants: both the ink
  /// controller and the box a splash is measured against are looked up from
  /// there, never from the host's own context, which sits above it.
  final GlobalKey _inkKey = GlobalKey();

  final HashSet<InteractiveInkFeature> _splashes =
      HashSet<InteractiveInkFeature>();

  InteractiveInkFeature? _current;

  @override
  void initState() {
    super.initState();
    widget.ink._attach(this);
  }

  @override
  void didUpdateWidget(PressInkHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.ink, widget.ink)) {
      oldWidget.ink._detach(this);
      widget.ink._attach(this);
    }
  }

  /// A surface can be taken off screen by the very tap it is animating — a
  /// menu entry that closes its menu. The ink still in flight is dropped
  /// here rather than in [dispose], because the [Material] that vsyncs it
  /// goes down with this subtree and would be left ticking for it.
  @override
  void deactivate() {
    for (final InteractiveInkFeature splash in _splashes.toList()) {
      splash.dispose();
    }
    _splashes.clear();
    _current = null;
    super.deactivate();
  }

  @override
  void dispose() {
    widget.ink._detach(this);
    super.dispose();
  }

  /// A press can land on a surface that is already on its way out — the
  /// sheet it belongs to is closing under the finger — and there is no ink
  /// controller left to give it to.
  void start(Offset? globalPosition) {
    final BuildContext? inkContext = _inkKey.currentContext;
    if (inkContext == null || !inkContext.mounted) return;
    final RenderBox box = inkContext.findRenderObject()! as RenderBox;
    if (!box.hasSize) return;

    _current?.cancel();
    InteractiveInkFeature? splash;
    splash = Theme.of(inkContext).splashFactory.create(
      controller: Material.of(inkContext),
      referenceBox: box,
      position: globalPosition == null
          ? box.size.center(Offset.zero)
          : box.globalToLocal(globalPosition),
      color: Theme.of(inkContext).splashColor,
      containedInkWell: true,
      borderRadius: widget.borderRadius,
      textDirection: Directionality.of(inkContext),
      onRemoved: () {
        _splashes.remove(splash);
        if (identical(_current, splash)) _current = null;
      },
    );
    _splashes.add(splash);
    _current = splash;
  }

  void confirm() {
    _current?.confirm();
    _current = null;
  }

  void cancel() {
    _current?.cancel();
    _current = null;
  }

  @override
  Widget build(BuildContext context) {
    // A Material hands its subtree bodyMedium unless told otherwise, which
    // would restyle every label this host is slipped under. Handing it back
    // the style already in force keeps the layer to what it is here for.
    return Material(
      type: MaterialType.transparency,
      textStyle: DefaultTextStyle.of(context).style,
      child: Builder(
        key: _inkKey,
        builder: (BuildContext context) => widget.child,
      ),
    );
  }
}
