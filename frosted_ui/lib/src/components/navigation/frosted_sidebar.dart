import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../primitives/frosted_glass.dart';
import '../../primitives/frosted_glass_level.dart';
import '../actions/_interactive_surface.dart';
import 'frosted_badge.dart';
import 'frosted_sidebar_section.dart';

const double _kDefaultWidth = 280;

/// A Liquid Glass desktop sidebar.
///
/// Supports a brand, an optional accent action button (e.g. "+ New task"),
/// a list of [FrostedSidebarSection]s, and a footer. Items are identified by
/// stable [FrostedSidebarItem.id] strings and tracked via [selectedId].
class FrostedSidebar extends StatelessWidget {
  const FrostedSidebar({
    required this.sections,
    this.brand,
    this.actionButton,
    this.footer,
    this.selectedId,
    this.width = _kDefaultWidth,
    this.level = FrostedGlassLevel.thick,
    this.tone = FrostedGlassTone.auto,
    super.key,
  });

  final List<FrostedSidebarSection> sections;
  final Widget? brand;
  final Widget? actionButton;
  final Widget? footer;
  final String? selectedId;
  final double width;
  final FrostedGlassLevel level;
  final FrostedGlassTone tone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.sp3),
        child: SizedBox(
          width: width,
          child: FrostedGlass(
            level: level,
            tone: tone,
            borderRadius: BorderRadius.circular(FrostedRadius.xl),
            padding: const EdgeInsets.all(FrostedSpacing.sp3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (brand != null) ...<Widget>[
                  brand!,
                  const SizedBox(height: FrostedSpacing.sp4),
                ],
                if (actionButton != null) ...<Widget>[
                  actionButton!,
                  const SizedBox(height: FrostedSpacing.sp3),
                ],
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: sections.length,
                    itemBuilder: (BuildContext context, int sectionIndex) {
                      final FrostedSidebarSection section =
                          sections[sectionIndex];
                      return _Section(
                        section: section,
                        selectedId: selectedId,
                        showSpacingTop: sectionIndex > 0,
                      );
                    },
                  ),
                ),
                if (footer != null) ...<Widget>[
                  const SizedBox(height: FrostedSpacing.sp3),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.selectedId,
    required this.showSpacingTop,
  });

  final FrostedSidebarSection section;
  final String? selectedId;
  final bool showSpacingTop;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showSpacingTop) const SizedBox(height: FrostedSpacing.sp3),
        if (section.title != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FrostedSpacing.sp2,
              0,
              FrostedSpacing.sp2,
              FrostedSpacing.sp1,
            ),
            child: Text(
              section.title!.toUpperCase(),
              style: FrostedTypeScale.labelSmall.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
        for (final FrostedSidebarItem item in section.items)
          _Item(item: item, selected: item.id == selectedId),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item, required this.selected});

  final FrostedSidebarItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = selected
        ? cs.onSurface.withValues(alpha: 0.10)
        : Colors.transparent;
    final Color fg = selected ? cs.onSurface : cs.onSurface;

    final Widget leading = item.leadingColor != null
        ? Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: item.leadingColor,
              shape: BoxShape.circle,
            ),
          )
        : Icon(item.icon, size: 18, color: fg);

    return InteractiveSurface(
      onTap: item.onTap,
      semanticsLabel: item.label,
      semanticsSelected: selected,
      builder: (BuildContext context, InteractionStates s) => DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FrostedRadius.sm),
        ),
        child: s.ink(
          color: fg,
          borderRadius: BorderRadius.circular(FrostedRadius.sm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedSpacing.sp2,
              vertical: FrostedSpacing.sp2,
            ),
            child: Row(
              children: <Widget>[
                leading,
                const SizedBox(width: FrostedSpacing.sp2),
                Expanded(
                  child: Text(
                    item.label,
                    style: FrostedTypeScale.labelLarge.copyWith(color: fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.badge != null) FrostedBadgeView(badge: item.badge!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
