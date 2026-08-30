import 'dart:math' as math;

class CarouselArrangement {
  const CarouselArrangement({
    required this.priority,
    required this.smallSize,
    required this.smallCount,
    required this.mediumSize,
    required this.mediumCount,
    required this.largeSize,
    required this.largeCount,
  });

  final int priority;
  final double smallSize;
  final int smallCount;
  final double mediumSize;
  final int mediumCount;
  final double largeSize;
  final int largeCount;

  static const double _mediumFlexPercentage = 0.1;

  int get itemCount => largeCount + mediumCount + smallCount;

  bool get _isValid {
    if (largeCount > 0 && smallCount > 0 && mediumCount > 0) {
      return largeSize > mediumSize && mediumSize > smallSize;
    } else if (largeCount > 0 && smallCount > 0) {
      return largeSize > smallSize;
    }
    return true;
  }

  double cost(double targetLargeSize) {
    if (!_isValid) return double.maxFinite;
    return (targetLargeSize - largeSize).abs() * priority;
  }

  static CarouselArrangement? findLowestCost({
    required double availableSpace,
    required double itemSpacing,
    required double targetSmallSize,
    required double minSmallSize,
    required double maxSmallSize,
    required List<int> smallCounts,
    required double targetMediumSize,
    required List<int> mediumCounts,
    required double targetLargeSize,
    required List<int> largeCounts,
  }) {
    CarouselArrangement? lowest;
    int priority = 1;
    for (final int largeCount in largeCounts) {
      for (final int mediumCount in mediumCounts) {
        for (final int smallCount in smallCounts) {
          final CarouselArrangement a = _fit(
            priority: priority,
            availableSpace: availableSpace,
            itemSpacing: itemSpacing,
            smallCount: smallCount,
            smallSize: targetSmallSize,
            minSmallSize: minSmallSize,
            maxSmallSize: maxSmallSize,
            mediumCount: mediumCount,
            mediumSize: targetMediumSize,
            largeCount: largeCount,
            largeSize: targetLargeSize,
          );
          if (lowest == null ||
              a.cost(targetLargeSize) < lowest.cost(targetLargeSize)) {
            lowest = a;
            if (lowest.cost(targetLargeSize) == 0) return lowest;
          }
          priority++;
        }
      }
    }
    return lowest;
  }

  static CarouselArrangement _fit({
    required int priority,
    required double availableSpace,
    required double itemSpacing,
    required int smallCount,
    required double smallSize,
    required double minSmallSize,
    required double maxSmallSize,
    required int mediumCount,
    required double mediumSize,
    required int largeCount,
    required double largeSize,
  }) {
    final int total = largeCount + mediumCount + smallCount;
    final double space = availableSpace - (total - 1) * itemSpacing;
    double small = smallSize.clamp(minSmallSize, maxSmallSize);

    final double taken =
        largeSize * largeCount + mediumSize * mediumCount + small * smallCount;
    final double delta = space - taken;
    if (smallCount > 0 && delta > 0) {
      small += math.min(delta / smallCount, maxSmallSize - small);
    } else if (smallCount > 0 && delta < 0) {
      small += math.max(delta / smallCount, minSmallSize - small);
    }
    small = smallCount > 0 ? small : 0;

    double large = _calculateLargeSize(
      space,
      smallCount,
      small,
      mediumCount,
      largeCount,
    );
    double medium = (large + small) / 2;

    if (mediumCount > 0 && large != largeSize) {
      final double targetAdjustment = (largeSize - large) * largeCount;
      final double availableFlex = medium * _mediumFlexPercentage * mediumCount;
      final double distribute = math.min(targetAdjustment.abs(), availableFlex);
      if (targetAdjustment > 0) {
        medium -= distribute / mediumCount;
        large += distribute / largeCount;
      } else {
        medium += distribute / mediumCount;
        large -= distribute / largeCount;
      }
    }

    return CarouselArrangement(
      priority: priority,
      smallSize: small,
      smallCount: smallCount,
      mediumSize: medium,
      mediumCount: mediumCount,
      largeSize: large,
      largeCount: largeCount,
    );
  }

  static double _calculateLargeSize(
    double availableSpace,
    int smallCount,
    double smallSize,
    int mediumCount,
    int largeCount,
  ) {
    return (availableSpace - (smallCount + mediumCount / 2) * smallSize) /
        (largeCount + mediumCount / 2);
  }
}
