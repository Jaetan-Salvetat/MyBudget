import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'destinations.dart';
import 'theme_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.controller, super.key});

  final ThemeController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<AppDestination> destinations = buildDestinations();
    final AppDestination current = destinations[_index];
    final Widget body = current.builder(context, widget.controller);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;

        if (width < FrostedBreakpoints.compact) {
          return _CompactShell(
            destinations: destinations,
            index: _index,
            currentTitle: current.title,
            body: body,
            onSelect: _select,
          );
        }

        if (width < FrostedBreakpoints.expanded) {
          return _RailShell(
            destinations: destinations,
            index: _index,
            currentTitle: current.title,
            body: body,
            extended: width >= FrostedBreakpoints.medium,
            onSelect: _select,
          );
        }

        return _SidebarShell(
          destinations: destinations,
          index: _index,
          currentTitle: current.title,
          body: body,
          onSelect: _select,
        );
      },
    );
  }

  void _select(int i) {
    setState(() => _index = i);
  }
}

class _CompactShell extends StatelessWidget {
  const _CompactShell({
    required this.destinations,
    required this.index,
    required this.currentTitle,
    required this.body,
    required this.onSelect,
  });

  final List<AppDestination> destinations;
  final int index;
  final String currentTitle;
  final Widget body;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: currentTitle,
        leading: Builder(
          builder: (BuildContext context) => InkResponse(
            onTap: () => FrostedScaffold.of(context).openDrawer(),
            radius: 22,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(Icons.menu, color: cs.onSurface, size: 22),
              ),
            ),
          ),
        ),
      ),
      drawer: Builder(
        builder: (BuildContext context) => FrostedDrawer(
          header: _ShellBrand(),
          items: destinations
              .map((AppDestination d) => d.toNavItem())
              .toList(growable: false),
          currentIndex: index,
          onTap: (int i) {
            onSelect(i);
            FrostedScaffold.of(context).closeDrawer();
          },
        ),
      ),
      body: body,
    );
  }
}

class _RailShell extends StatelessWidget {
  const _RailShell({
    required this.destinations,
    required this.index,
    required this.currentTitle,
    required this.body,
    required this.extended,
    required this.onSelect,
  });

  final List<AppDestination> destinations;
  final int index;
  final String currentTitle;
  final Widget body;
  final bool extended;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      appBar: FrostedTopBar(title: currentTitle),
      body: Row(
        children: <Widget>[
          FrostedNavigationRail(
            items: destinations
                .map((AppDestination d) => d.toNavItem())
                .toList(growable: false),
            currentIndex: index,
            onTap: onSelect,
            extended: extended,
            header: _ShellBrandCompact(),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _SidebarShell extends StatelessWidget {
  const _SidebarShell({
    required this.destinations,
    required this.index,
    required this.currentTitle,
    required this.body,
    required this.onSelect,
  });

  final List<AppDestination> destinations;
  final int index;
  final String currentTitle;
  final Widget body;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      appBar: FrostedTopBar(title: currentTitle),
      body: Row(
        children: <Widget>[
          FrostedSidebar(
            brand: _ShellBrand(),
            selectedId: destinations[index].title,
            sections: <FrostedSidebarSection>[
              FrostedSidebarSection(
                title: 'Showcase',
                items: <FrostedSidebarItem>[
                  for (int i = 0; i < destinations.length; i++)
                    FrostedSidebarItem(
                      id: destinations[i].title,
                      icon: i == index
                          ? destinations[i].selectedIcon
                          : destinations[i].icon,
                      label: destinations[i].title,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ],
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ShellBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.sp2,
        vertical: FrostedSpacing.sp2,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[cs.primary, cs.tertiary],
              ),
              borderRadius: BorderRadius.circular(FrostedRadius.xs),
            ),
          ),
          const SizedBox(width: FrostedSpacing.sp2),
          Text(
            'Frosted UI',
            style: FrostedTypeScale.titleMedium
                .copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}

class _ShellBrandCompact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[cs.primary, cs.tertiary],
          ),
          borderRadius: BorderRadius.circular(FrostedRadius.xs),
        ),
      ),
    );
  }
}
