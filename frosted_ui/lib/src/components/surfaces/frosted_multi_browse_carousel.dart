import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '_carousel_arrangement.dart';

/// An M3 Expressive multi-browse carousel.
///
/// Item sizes come from the real Material 3 arrangement algorithm (ported from
/// androidx's `Arrangement` / `multiBrowseKeylineList`): large items target
/// [preferredItemWidth], small items clamp to 40–56dp, a medium item bridges
/// them, and the lowest-cost arrangement that fills the width wins. Those
/// sizes drive the `flexWeights` of [CarouselView.weighted], which resizes
/// items continuously as the list scrolls.
///
/// Items provide their own surface; corners follow [FrostedRadius.lg].
class FrostedMultiBrowseCarousel extends StatelessWidget {
  const FrostedMultiBrowseCarousel({
    required this.items,
    this.height = 220,
    this.preferredItemWidth = 200,
    this.itemSpacing = 8,
    this.onTap,
    super.key,
  });

  final List<Widget> items;
  final double height;
  final double preferredItemWidth;
  final double itemSpacing;
  final ValueChanged<int>? onTap;

  // M3 CarouselDefaults.
  static const double _minSmall = 40;
  static const double _maxSmall = 56;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final List<int> weights = _flexWeights(constraints.maxWidth);
          final double half = itemSpacing / 2;
          return CarouselView.weighted(
            flexWeights: weights,
            itemSnapping: true,
            enableSplash: false,
            padding: EdgeInsets.symmetric(horizontal: half),
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FrostedRadius.lg),
            ),
            onTap: onTap,
            children: items,
          );
        },
      ),
    );
  }

  /// Turns the lowest-cost M3 arrangement into integer flex weights — one per
  /// visible item, in size order (large… medium, small).
  List<int> _flexWeights(double width) {
    final double targetLarge = preferredItemWidth.clamp(0, width);
    final double targetSmall =
        (targetLarge / 3).clamp(_minSmall, _maxSmall).toDouble();
    final double targetMedium = (targetLarge + targetSmall) / 2;

    final double minLargeSpace = width - targetMedium - _maxSmall;
    final int minLargeCount = minLargeSpace <= 0
        ? 1
        : (minLargeSpace / targetLarge).floor().clamp(1, 999);
    final int maxLargeCount = (width / targetLarge).ceil();
    final List<int> largeCounts = <int>[
      for (int c = maxLargeCount; c >= minLargeCount; c--) c,
    ];

    final CarouselArrangement? a = CarouselArrangement.findLowestCost(
      availableSpace: width,
      itemSpacing: itemSpacing,
      targetSmallSize: targetSmall,
      minSmallSize: _minSmall,
      maxSmallSize: _maxSmall,
      smallCounts: const <int>[1],
      targetMediumSize: targetMedium,
      mediumCounts: const <int>[1, 0],
      targetLargeSize: targetLarge,
      largeCounts: largeCounts.isEmpty ? const <int>[1] : largeCounts,
    );

    if (a == null) return const <int>[1];

    final List<int> weights = <int>[
      for (int i = 0; i < a.largeCount; i++) a.largeSize.round(),
      for (int i = 0; i < a.mediumCount; i++) a.mediumSize.round(),
      for (int i = 0; i < a.smallCount; i++) a.smallSize.round(),
    ];
    return weights.where((int w) => w > 0).toList();
  }
}
