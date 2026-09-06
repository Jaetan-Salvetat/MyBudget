import 'package:material_ui/material_ui.dart';

enum CategoryIconSize { xs, sm, md }

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = CategoryIconSize.md,
  });
  final IconData icon;
  final Color color;
  final CategoryIconSize size;

  @override
  Widget build(BuildContext context) {
    final dimensions = _dimensions(size);
    return Container(
      width: dimensions.box,
      height: dimensions.box,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(dimensions.radius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: dimensions.icon, fill: 1),
    );
  }

  _IconDimensions _dimensions(CategoryIconSize size) {
    switch (size) {
      case CategoryIconSize.xs:
        return const _IconDimensions(box: 24, radius: 8, icon: 14);
      case CategoryIconSize.sm:
        return const _IconDimensions(box: 32, radius: 10, icon: 18);
      case CategoryIconSize.md:
        return const _IconDimensions(box: 40, radius: 12, icon: 22);
    }
  }
}

class _IconDimensions {
  const _IconDimensions({
    required this.box,
    required this.radius,
    required this.icon,
  });
  final double box;
  final double radius;
  final double icon;
}
