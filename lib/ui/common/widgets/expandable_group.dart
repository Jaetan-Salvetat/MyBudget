import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

const Duration _expandDuration = Duration(milliseconds: 220);

class ExpandableGroup extends StatefulWidget {
  const ExpandableGroup({
    required this.header,
    required this.children,
    required this.expanded,
    super.key,
  });
  final Widget header;
  final List<Widget> children;
  final bool expanded;

  @override
  State<ExpandableGroup> createState() => _ExpandableGroupState();
}

class _ExpandableGroupState extends State<ExpandableGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _expandDuration,
    value: widget.expanded ? 1 : 0,
  );
  late final Animation<double> _openness = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  bool get _closed => !widget.expanded && _controller.isDismissed;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_dropChildrenWhenClosed);
  }

  void _dropChildrenWhenClosed(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) setState(() {});
  }

  @override
  void didUpdateWidget(ExpandableGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded == oldWidget.expanded) return;

    if (widget.expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.header,
        if (!_closed)
          AnimatedBuilder(
            animation: _openness,
            builder: (context, child) => ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _openness.value,
                child: Opacity(opacity: _openness.value, child: child),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}

class ExpandChevron extends StatelessWidget {
  const ExpandChevron({required this.expanded, super.key});
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: expanded ? 0.5 : 0,
      duration: _expandDuration,
      curve: Curves.easeOutCubic,
      child: Icon(
        Symbols.expand_more_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
