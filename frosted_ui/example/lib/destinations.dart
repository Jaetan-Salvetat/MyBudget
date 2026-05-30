import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'pages/actions_page.dart';
import 'pages/foundations_page.dart';
import 'pages/glass_page.dart';
import 'pages/navigation_page.dart';
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

  FrostedNavItem toNavItem() => FrostedNavItem(
        icon: icon,
        selectedIcon: selectedIcon,
        label: title,
      );
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
    ];
