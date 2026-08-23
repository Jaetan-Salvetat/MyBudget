import 'package:flutter/material.dart';

class BeneficiaryAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final int? avatarColor;
  final String? initials;
  final BorderRadius? borderRadius;

  const BeneficiaryAvatar({
    required this.name,
    this.radius = 20,
    this.avatarColor,
    this.initials,
    this.borderRadius,
    super.key,
  });

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

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: bgColor,
        shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
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
