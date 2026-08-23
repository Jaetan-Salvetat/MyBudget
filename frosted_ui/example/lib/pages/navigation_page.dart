import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../widgets/section.dart';
import 'navigation/top_bar_demo.dart';

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
        FrostedSpacing.sp4,
        FrostedSpacing.sp4,
      ),
      children: const <Widget>[
        Section(
          title: 'Tab bar',
          child: _TabBarDemo(),
        ),
        SizedBox(height: FrostedSpacing.sp6),
        Section(
          title: 'Top bar (large, collapsible)',
          child: TopBarLargeDemo(),
        ),
        SizedBox(height: FrostedSpacing.sp6),
        Section(
          title: 'Toolbar (desktop)',
          child: _ToolbarDemo(),
        ),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Tabs', child: _TabsDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Segmented control', child: _SegmentedDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Stepper', child: _StepperDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Breadcrumb', child: _BreadcrumbDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Page indicator', child: _PageIndicatorDemo()),
        SizedBox(height: FrostedSpacing.sp7),
      ],
    );
  }
}

class _TabBarDemo extends StatefulWidget {
  const _TabBarDemo();

  @override
  State<_TabBarDemo> createState() => _TabBarDemoState();
}

class _TabBarDemoState extends State<_TabBarDemo> {
  int _index = 0;

  static const List<FrostedNavItem> _items = <FrostedNavItem>[
    FrostedNavItem(icon: Icons.home_outlined, label: 'Home'),
    FrostedNavItem(icon: Icons.search, label: 'Search'),
    FrostedNavItem(
      icon: Icons.bookmark_outline,
      label: 'Library',
      badge: FrostedBadge.count(3),
    ),
    FrostedNavItem(icon: Icons.person_outline, label: 'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FrostedRadius.lg),
      child: SizedBox(
        height: 180,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            const Positioned.fill(child: _MiniFeed()),
            Padding(
              padding: const EdgeInsets.all(FrostedSpacing.sp3),
              child: FrostedNavPill(
                destinations: _items,
                selectedIndex: _index,
                onDestinationSelected: (int i) => setState(() => _index = i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarDemo extends StatelessWidget {
  const _ToolbarDemo();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(FrostedRadius.lg),
      child: SizedBox(
        height: 140,
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: _MiniFeed()),
            FrostedToolbar(
              breadcrumbs: const <String>['Projects', 'Refraction', 'Settings'],
              onBreadcrumbTap: (_) {},
              onSearchTap: () {},
              actions: <Widget>[
                _ToolbarBtn(icon: Icons.notifications_outlined),
                _ToolbarBtn(
                  icon: Icons.add,
                  filled: true,
                  label: 'New',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.icon,
    this.filled = false,
    this.label,
    this.onTap,
  });

  final IconData icon;
  final bool filled;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = filled ? cs.primary : Colors.transparent;
    final Color fg = filled ? cs.onPrimary : cs.onSurface;
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(FrostedRadius.sm),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FrostedRadius.sm),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? FrostedSpacing.sp2 : FrostedSpacing.sp3,
          vertical: FrostedSpacing.sp2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: fg),
            if (label != null) ...<Widget>[
              const SizedBox(width: FrostedSpacing.sp1),
              Text(
                label!,
                style: FrostedTypeScale.labelMedium
                    .copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabsDemo extends StatefulWidget {
  const _TabsDemo();

  @override
  State<_TabsDemo> createState() => _TabsDemoState();
}

class _TabsDemoState extends State<_TabsDemo> {
  int _primary = 0;
  int _secondary = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedTabs(
          tabs: const <FrostedTab>[
            FrostedTab(label: 'Profile', icon: Icons.person_outline),
            FrostedTab(label: 'Posts', icon: Icons.article_outlined),
            FrostedTab(label: 'Photos', icon: Icons.photo_outlined),
          ],
          currentIndex: _primary,
          onTap: (int i) => setState(() => _primary = i),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        FrostedTabs(
          tabs: const <FrostedTab>[
            FrostedTab(label: 'Overview'),
            FrostedTab(label: 'Activity'),
            FrostedTab(label: 'Insights'),
            FrostedTab(label: 'Schedule'),
            FrostedTab(label: 'Reports'),
            FrostedTab(label: 'Settings'),
          ],
          currentIndex: _secondary,
          onTap: (int i) => setState(() => _secondary = i),
          variant: FrostedTabsVariant.secondary,
        ),
      ],
    );
  }
}

class _SegmentedDemo extends StatefulWidget {
  const _SegmentedDemo();

  @override
  State<_SegmentedDemo> createState() => _SegmentedDemoState();
}

class _SegmentedDemoState extends State<_SegmentedDemo> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    return FrostedSegmentedControl(
      segments: const <String>['Day', 'Week', 'Month'],
      currentIndex: _index,
      onTap: (int i) => setState(() => _index = i),
    );
  }
}

class _StepperDemo extends StatefulWidget {
  const _StepperDemo();

  @override
  State<_StepperDemo> createState() => _StepperDemoState();
}

class _StepperDemoState extends State<_StepperDemo> {
  int _step = 1;

  static const List<FrostedStep> _steps = <FrostedStep>[
    FrostedStep(title: 'Account', subtitle: 'Name and email'),
    FrostedStep(title: 'Workspace', subtitle: 'Pick a team or solo'),
    FrostedStep(title: 'Preferences', subtitle: 'Theme and locale'),
    FrostedStep(title: 'Done', subtitle: 'Wrap up'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedStepper(
          steps: _steps,
          currentStep: _step,
          onStepTapped: (int i) => setState(() => _step = i),
        ),
        const SizedBox(height: FrostedSpacing.sp5),
        FrostedStepper(
          steps: _steps,
          currentStep: _step,
          onStepTapped: (int i) => setState(() => _step = i),
          axis: Axis.vertical,
        ),
      ],
    );
  }
}

class _BreadcrumbDemo extends StatelessWidget {
  const _BreadcrumbDemo();

  @override
  Widget build(BuildContext context) {
    return FrostedBreadcrumb(
      crumbs: const <String>['Home', 'Projects', 'Refraction', 'Settings'],
      onTap: (_) {},
    );
  }
}

class _PageIndicatorDemo extends StatefulWidget {
  const _PageIndicatorDemo();

  @override
  State<_PageIndicatorDemo> createState() => _PageIndicatorDemoState();
}

class _PageIndicatorDemoState extends State<_PageIndicatorDemo> {
  int _index = 0;
  static const int _count = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
          child: FrostedPageIndicator(count: _count, currentIndex: _index),
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        Center(
          child: FrostedPageIndicator(
            count: _count,
            currentIndex: _index,
            style: FrostedPageIndicatorStyle.bar,
          ),
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        Center(
          child: Wrap(
            spacing: FrostedSpacing.sp2,
            children: <Widget>[
              FilledButton.tonal(
                onPressed: () => setState(
                  () => _index = (_index - 1).clamp(0, _count - 1),
                ),
                child: const Text('Prev'),
              ),
              FilledButton.tonal(
                onPressed: () => setState(
                  () => _index = (_index + 1).clamp(0, _count - 1),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniFeed extends StatelessWidget {
  const _MiniFeed();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(FrostedSpacing.sp3),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: FrostedSpacing.sp2),
      itemBuilder: (BuildContext context, int index) {
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(FrostedRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedSpacing.sp3,
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            'Row ${index + 1}',
            style: FrostedTypeScale.bodyMedium
                .copyWith(color: cs.onSurfaceVariant),
          ),
        );
      },
    );
  }
}
