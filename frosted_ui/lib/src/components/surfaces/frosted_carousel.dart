import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_spacing.dart';
import '../navigation/frosted_page_indicator.dart';

class FrostedCarousel extends StatefulWidget {
  const FrostedCarousel({
    required this.items,
    this.height = 180,
    this.viewportFraction = 0.9,
    this.itemSpacing = FrostedSpacing.sp3,
    this.showIndicator = true,
    this.onPageChanged,
    super.key,
  });

  final List<Widget> items;
  final double height;
  final double viewportFraction;
  final double itemSpacing;
  final bool showIndicator;
  final ValueChanged<int>? onPageChanged;

  @override
  State<FrostedCarousel> createState() => _FrostedCarouselState();
}

class _FrostedCarouselState extends State<FrostedCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: widget.viewportFraction,
  );
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(int i) {
    setState(() => _index = i);
    widget.onPageChanged?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: _onChanged,
            itemBuilder: (BuildContext context, int i) => Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.itemSpacing / 2),
              child: widget.items[i],
            ),
          ),
        ),
        if (widget.showIndicator && widget.items.length > 1) ...<Widget>[
          const SizedBox(height: FrostedSpacing.sp3),
          FrostedPageIndicator(
            count: widget.items.length,
            currentIndex: _index,
          ),
        ],
      ],
    );
  }
}
