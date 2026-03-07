import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';

class FinancialSummaryCard extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Color primaryColor;
  final double amount;
  final IconData trendIcon;
  final int itemCount;
  final NumberFormat formatter;
  final Widget childContent;

  const FinancialSummaryCard({
    required this.title,
    required this.titleIcon,
    required this.primaryColor,
    required this.amount,
    required this.trendIcon,
    required this.itemCount,
    required this.formatter,
    required this.childContent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.1),
                  primaryColor.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(titleIcon, color: primaryColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '$itemCount transactions',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatter.format(amount),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Icon(trendIcon, color: primaryColor, size: 20),
                  ],
                ),
              ],
            ),
          ),
          childContent,
        ],
      ),
    );
  }
}
