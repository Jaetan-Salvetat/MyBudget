import 'package:flutter/material.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.eyebrowMono(color: color).copyWith(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.99,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: AppTextStyles.eyebrowMono(color: color).copyWith(
                fontSize: 11,
                height: 14 / 11,
              ),
            ),
        ],
      ),
    );
  }
}
