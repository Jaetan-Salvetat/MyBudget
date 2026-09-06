import 'package:material_ui/material_ui.dart';

class BeneficiaryAvatar extends StatelessWidget {
  const BeneficiaryAvatar({
    required this.name,
    this.radius = 20,
    this.avatarColor,
    this.initials,
    super.key,
  });
  final String name;
  final double radius;
  final int? avatarColor;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    final displayInitials =
        initials ?? name.trim().substring(0, 1).toUpperCase();
    final hasColor = avatarColor != null && avatarColor != 0;

    final bgColor = hasColor
        ? Color(avatarColor!).withValues(alpha: 0.2)
        : Theme.of(context).colorScheme.primaryContainer;

    final textColor = hasColor
        ? Color(avatarColor!)
        : Theme.of(context).colorScheme.onPrimaryContainer;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        displayInitials,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
