import 'package:material_ui/material_ui.dart';

class FrostedListAvatar extends StatelessWidget {
  const FrostedListAvatar({required this.icon, super.key});

  final IconData icon;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: cs.onSecondaryContainer),
    );
  }
}
