import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/entities/beneficiary.dart';

const double _slotSize = 36;
const double _avatarSize = 32;
const double _iconSize = 17;
const BorderRadius _avatarRadius = BorderRadius.all(Radius.circular(10));
const double _badgeHeight = 18;
const double _badgeOffset = -2;
const double _badgeBorderWidth = 1.5;
const double _badgeFontSize = 10;
const EdgeInsets _badgePadding = EdgeInsets.symmetric(horizontal: 4);

class TransactionAvatar extends StatelessWidget {
  const TransactionAvatar({
    required this.color,
    required this.icon,
    this.beneficiary,
    super.key,
  });
  final Color color;
  final IconData icon;
  final Beneficiary? beneficiary;

  @override
  Widget build(BuildContext context) {
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
              color: color,
              borderRadius: _avatarRadius,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: _iconSize),
          ),
          if (beneficiary != null)
            Positioned(
              bottom: _badgeOffset,
              right: _badgeOffset,
              child: _BeneficiaryBadge(beneficiary: beneficiary!),
            ),
        ],
      ),
    );
  }
}

class _BeneficiaryBadge extends StatelessWidget {
  const _BeneficiaryBadge({required this.beneficiary});
  final Beneficiary beneficiary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasOwnColor = beneficiary.color != 0;
    return Container(
      height: _badgeHeight,
      padding: _badgePadding,
      decoration: BoxDecoration(
        color: hasOwnColor ? Color(beneficiary.color) : scheme.primary,
        borderRadius: const BorderRadius.all(Radius.circular(_badgeHeight / 2)),
        border: Border.all(color: scheme.surface, width: _badgeBorderWidth),
      ),
      alignment: Alignment.center,
      child: Text(
        beneficiary.initials,
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
