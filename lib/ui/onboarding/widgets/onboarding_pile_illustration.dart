import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';

class OnboardingPileIllustration extends StatelessWidget {
  const OnboardingPileIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;

    final cards = <_PileCardData>[
      _PileCardData(
        icon: Symbols.home_rounded,
        color: scheme.primary,
        label: 'Loyer',
        amount: '720,00 €',
        top: 30,
        left: 12,
        width: 220,
        rotationDeg: -6,
      ),
      _PileCardData(
        icon: Symbols.subscriptions_rounded,
        color: finance.expense,
        label: 'Netflix',
        amount: '13,99 €',
        top: 92,
        left: 36,
        width: 200,
        rotationDeg: 3,
      ),
      _PileCardData(
        icon: Symbols.shopping_cart_rounded,
        color: finance.income,
        label: 'Courses',
        amount: '47,32 €',
        top: 152,
        left: 16,
        width: 218,
        rotationDeg: -2,
      ),
      _PileCardData(
        icon: Symbols.directions_subway_rounded,
        color: scheme.tertiary,
        label: 'Navigo',
        amount: '86,40 €',
        top: 210,
        left: 30,
        width: 206,
        rotationDeg: 5,
      ),
    ];

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final card in cards)
            Positioned(
              top: card.top,
              left: card.left,
              child: Transform.rotate(
                angle: card.rotationDeg * math.pi / 180,
                child: _PileCard(data: card),
              ),
            ),
        ],
      ),
    );
  }
}

class _PileCardData {
  final IconData icon;
  final Color color;
  final String label;
  final String amount;
  final double top;
  final double left;
  final double width;
  final double rotationDeg;

  const _PileCardData({
    required this.icon,
    required this.color,
    required this.label,
    required this.amount,
    required this.top,
    required this.left,
    required this.width,
    required this.rotationDeg,
  });
}

class _PileCard extends StatelessWidget {
  final _PileCardData data;

  const _PileCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: data.width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 0.5,
          color: scheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CategoryIcon(
            icon: data.icon,
            color: data.color,
            size: CategoryIconSize.sm,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 14,
                height: 18 / 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            data.amount,
            style: const TextStyle(
              fontSize: 14,
              height: 18 / 14,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
