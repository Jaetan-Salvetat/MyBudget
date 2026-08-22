import 'package:flutter/material.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class FrequencyBadge extends StatelessWidget {
  final Frequency frequency;

  const FrequencyBadge({super.key, required this.frequency});

  @override
  Widget build(BuildContext context) {
    if (frequency == Frequency.oneTime) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final isMonthly = frequency == Frequency.monthly;
    final color = isMonthly
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    final label = isMonthly ? 'M' : 'A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.eyebrowMono(
          color: color,
        ).copyWith(fontSize: 10, height: 13 / 10, letterSpacing: 0),
      ),
    );
  }
}
