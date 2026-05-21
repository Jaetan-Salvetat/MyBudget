import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const AppTopBar({
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(FrostedSize.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FrostedAppBar(
      title: title,
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      titleStyle: TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.018 * 22,
        color: scheme.onSurface,
      ),
    );
  }
}
