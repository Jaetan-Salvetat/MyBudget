import 'package:flutter/material.dart';

class TransactionTabs extends StatelessWidget {
  final TabController tabController;
  final List<String> tabLabels;
  final List<Color> tabColors;

  const TransactionTabs({
    Key? key,
    required this.tabController,
    required this.tabLabels,
    required this.tabColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.7),
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
        dividerColor: Colors.transparent,
        physics: const BouncingScrollPhysics(),
        splashBorderRadius: BorderRadius.circular(10),
        overlayColor: MaterialStateProperty.resolveWith<Color?>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.pressed)) {
            return Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3);
          }
          return null;
        }),
        tabs: List.generate(
          tabLabels.length,
          (index) => Tab(child: Text(tabLabels[index])),
        ),
      ),
    );
  }
}
