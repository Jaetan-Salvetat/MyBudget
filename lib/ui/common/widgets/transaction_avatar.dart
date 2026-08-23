import 'package:flutter/material.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_avatar.dart';

const double _slotSize = 36;
const double _avatarSize = 32;
const double _iconSize = 17;
const double _squareCornerRadius = 10;
const double _circleCornerRadius = _avatarSize / 2;
const double _surfaceGapSpread = 1.5;
const double _ringSpread = 3;
const double _badgeSize = 15;
const double _badgeOffset = -2;
const double _badgeBorderWidth = 1.5;
const double _badgeFontSize = 9;

class TransactionAvatar extends StatelessWidget {
  final Widget avatar;
  final Color? avatarColor;
  final BorderRadius borderRadius;
  final Color? ringColor;
  final String? badgeLetter;
  final Color badgeColor;

  TransactionAvatar.category({
    required Color color,
    required IconData icon,
    required this.badgeColor,
    this.ringColor,
    this.badgeLetter,
    super.key,
  }) : avatar = _SolidIcon(icon: icon),
       avatarColor = color,
       borderRadius = const BorderRadius.all(
         Radius.circular(_squareCornerRadius),
       );

  TransactionAvatar.beneficiary({
    required Beneficiary? beneficiary,
    required Color fallbackColor,
    required IconData fallbackIcon,
    required this.badgeColor,
    this.ringColor,
    this.badgeLetter,
    super.key,
  }) : avatar = _BeneficiaryOrIcon(
         beneficiary: beneficiary,
         fallbackColor: fallbackColor,
         fallbackIcon: fallbackIcon,
       ),
       avatarColor = null,
       borderRadius = const BorderRadius.all(
         Radius.circular(_circleCornerRadius),
       );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: _slotSize,
      height: _slotSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: borderRadius,
              boxShadow: ringColor != null
                  ? [
                      BoxShadow(
                        color: scheme.surface,
                        spreadRadius: _surfaceGapSpread,
                      ),
                      BoxShadow(color: ringColor!, spreadRadius: _ringSpread),
                    ]
                  : null,
            ),
            child: ClipRRect(borderRadius: borderRadius, child: avatar),
          ),
          if (badgeLetter != null)
            Positioned(
              bottom: _badgeOffset,
              right: _badgeOffset,
              child: _Badge(letter: badgeLetter!, color: badgeColor),
            ),
        ],
      ),
    );
  }
}

class _SolidIcon extends StatelessWidget {
  final IconData icon;

  const _SolidIcon({required this.icon});

  @override
  Widget build(BuildContext context) =>
      Icon(icon, color: Colors.white, size: _iconSize);
}

class _BeneficiaryOrIcon extends StatelessWidget {
  final Beneficiary? beneficiary;
  final Color fallbackColor;
  final IconData fallbackIcon;

  const _BeneficiaryOrIcon({
    required this.beneficiary,
    required this.fallbackColor,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (beneficiary != null) {
      return BeneficiaryAvatar(
        name: beneficiary!.name,
        initials: beneficiary!.initials,
        avatarColor: beneficiary!.color,
        radius: _circleCornerRadius,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fallbackColor.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(fallbackIcon, color: fallbackColor, size: _iconSize),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String letter;
  final Color color;

  const _Badge({required this.letter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _badgeSize,
      height: _badgeSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: _badgeBorderWidth,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: _badgeFontSize,
          height: 1,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
