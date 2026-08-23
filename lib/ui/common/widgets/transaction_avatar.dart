import 'package:flutter/material.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_avatar.dart';

const double _slotSize = 36;
const double _avatarSize = 32;
const double _iconSize = 17;
const BorderRadius _avatarRadius = BorderRadius.all(Radius.circular(10));
const double _badgeSize = 15;
const double _badgeOffset = -2;
const double _badgeBorderWidth = 1.5;
const double _badgeFontSize = 9;

class TransactionAvatar extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color badgeColor;
  final Beneficiary? beneficiary;
  final String? badgeLetter;

  const TransactionAvatar({
    required this.color,
    required this.icon,
    required this.badgeColor,
    this.beneficiary,
    this.badgeLetter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _slotSize,
      height: _slotSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          beneficiary != null
              ? BeneficiaryAvatar(
                  name: beneficiary!.name,
                  initials: beneficiary!.initials,
                  avatarColor: beneficiary!.color,
                  radius: _avatarSize / 2,
                  borderRadius: _avatarRadius,
                )
              : Container(
                  width: _avatarSize,
                  height: _avatarSize,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: _avatarRadius,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: _iconSize),
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
