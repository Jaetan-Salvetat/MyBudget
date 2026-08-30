import 'dart:collection';

import 'package:material_ui/material_ui.dart';

class PressInk {
  _PressInkHostState? _host;

  void _attach(_PressInkHostState host) => _host = host;

  void _detach(_PressInkHostState host) {
    if (identical(_host, host)) _host = null;
  }

  void start({Offset? globalPosition}) => _host?.start(globalPosition);

  void confirm() => _host?.confirm();

  void cancel() => _host?.cancel();
}

class PressInkHost extends StatefulWidget {
  const PressInkHost({required this.ink, required this.child, super.key});

  final PressInk ink;

  final Widget child;

  @override
  State<PressInkHost> createState() => _PressInkHostState();
}

class _PressInkHostState extends State<PressInkHost> {
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
