import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';

/// One taxonomy row, shared by the picker and the settings screen.
class CategoryTile extends StatelessWidget {
  final CategoryDisplay category;
  final String? subtitle;
  final bool selected;
  final bool indented;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CategoryTile({
    required this.category,
    this.subtitle,
    this.selected = false,
    this.indented = false,
    this.trailing,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);

    return FrostedListTile(
      leading: CategoryIcon(
        icon: CategoryDefaults.resolveIcon(category.icon),
        color: color,
        size: category.isGroup ? CategoryIconSize.sm : CategoryIconSize.xs,
      ),
      title: category.label,
      subtitle: subtitle,
      trailing:
          trailing ??
          (selected ? Icon(Symbols.check_rounded, color: color) : null),
      selected: selected,
      onTap: onTap,
    );
  }
}
