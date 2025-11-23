import 'package:flutter/material.dart';

class RestartWidget extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRestart;

  const RestartWidget({super.key, required this.child, this.onRestart});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() async {
    if (widget.onRestart != null) {
      await widget.onRestart!();
    }
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: key, child: widget.child);
  }
}
