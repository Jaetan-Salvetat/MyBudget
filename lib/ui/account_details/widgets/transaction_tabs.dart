import 'package:flutter/material.dart';

class TransactionTabs extends StatelessWidget {
  final TabController tabController;
  final List<String> tabLabels;
  final List<Color> tabColors;

  const TransactionTabs({
    required this.tabController,
    required this.tabLabels,
    required this.tabColors,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, child) {
        return Container(
          height: 45,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: tabColors[tabController.index].withValues(alpha: 0.1),
              border: Border.all(
                color: tabColors[tabController.index].withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            labelColor: tabColors[tabController.index],
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
            splashBorderRadius: BorderRadius.circular(25),
            tabs: tabLabels.map((label) => Tab(text: label)).toList(),
          ),
        );
      },
    );
  }
}
