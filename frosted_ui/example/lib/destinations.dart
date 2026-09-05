import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'pages/actions_page.dart';
import 'pages/charts_page.dart';
import 'pages/foundations_page.dart';
import 'pages/glass_page.dart';
import 'pages/indicators_page.dart';
import 'pages/inputs_page.dart';
import 'pages/navigation_page.dart';
import 'pages/overlays_page.dart';
import 'pages/surfaces_page.dart';
import 'theme_controller.dart';

class AppDestination {
  const AppDestination({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function(BuildContext context, ThemeController controller)
  builder;

  FrostedNavItem toNavItem() =>
      FrostedNavItem(icon: icon, selectedIcon: selectedIcon, label: title);
}

List<AppDestination> buildDestinations() => <AppDestination>[
  AppDestination(
    title: 'Foundations',
    icon: Icons.palette_outlined,
    selectedIcon: Icons.palette,
    builder: (_, ThemeController c) => FoundationsPage(controller: c),
  ),
  AppDestination(
    title: 'Glass',
    icon: Icons.layers_outlined,
    selectedIcon: Icons.layers,
    builder: (_, _) => const GlassPage(),
  ),
  AppDestination(
    title: 'Navigation',
    icon: Icons.alt_route_outlined,
    selectedIcon: Icons.alt_route,
    builder: (_, _) => const NavigationPage(),
  ),
  AppDestination(
    title: 'Actions',
    icon: Icons.touch_app_outlined,
    selectedIcon: Icons.touch_app,
    builder: (_, _) => const ActionsPage(),
  ),
  AppDestination(
    title: 'Inputs',
    icon: Icons.edit_outlined,
    selectedIcon: Icons.edit,
    builder: (_, _) => const InputsPage(),
  ),
  AppDestination(
    title: 'Indicators',
    icon: Icons.speed_outlined,
    selectedIcon: Icons.speed,
    builder: (_, _) => const IndicatorsPage(),
  ),
  AppDestination(
    title: 'Charts',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    builder: (_, _) => const ChartsPage(),
  ),
  AppDestination(
    title: 'Surfaces',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    builder: (_, _) => const SurfacesPage(),
  ),
  AppDestination(
    title: 'Overlays',
    icon: Icons.layers_clear_outlined,
    selectedIcon: Icons.layers_clear,
    builder: (_, _) => const OverlaysPage(),
  ),
];
