import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../widgets/realistic_surface.dart';

class GlassPage extends StatefulWidget {
  const GlassPage({super.key});

  @override
  State<GlassPage> createState() => _GlassPageState();
}

class _GlassPageState extends State<GlassPage> {
  FrostedGlassLevel _level = FrostedGlassLevel.regular;
  FrostedGlassTone _tone = FrostedGlassTone.auto;
  FrostedGlassElevation _elevation = FrostedGlassElevation.floating;
  RealisticSurfaceKind _surface = RealisticSurfaceKind.feed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: RealisticSurface(kind: _surface)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(FrostedSpacing.sp4),
              child: Row(
                children: <Widget>[
                  _ChromePill(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back, size: 20),
                  ),
                  const Spacer(),
                  _ChromePill(
                    onTap: () => setState(() {
                      final int next = (_surface.index + 1) %
                          RealisticSurfaceKind.values.length;
                      _surface = RealisticSurfaceKind.values[next];
                    }),
                    child: const Icon(Icons.layers_outlined, size: 20),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  FrostedSpacing.sp4,
                  0,
                  FrostedSpacing.sp4,
                  FrostedSpacing.sp4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _ControlsPanel(
                      level: _level,
                      tone: _tone,
                      elevation: _elevation,
                      onLevelChanged: (FrostedGlassLevel v) =>
                          setState(() => _level = v),
                      onToneChanged: (FrostedGlassTone v) =>
                          setState(() => _tone = v),
                      onElevationChanged: (FrostedGlassElevation v) =>
                          setState(() => _elevation = v),
                    ),
                    const SizedBox(height: FrostedSpacing.sp3),
                    FrostedGlass(
                      level: _level,
                      tone: _tone,
                      elevation: _elevation,
                      borderRadius:
                          BorderRadius.circular(FrostedRadius.full),
                      padding: EdgeInsets.zero,
                      child: const _SampleTabBar(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.level,
    required this.tone,
    required this.elevation,
    required this.onLevelChanged,
    required this.onToneChanged,
    required this.onElevationChanged,
  });

  final FrostedGlassLevel level;
  final FrostedGlassTone tone;
  final FrostedGlassElevation elevation;
  final ValueChanged<FrostedGlassLevel> onLevelChanged;
  final ValueChanged<FrostedGlassTone> onToneChanged;
  final ValueChanged<FrostedGlassElevation> onElevationChanged;

  static const Map<FrostedGlassLevel, String> _levelLabels =
      <FrostedGlassLevel, String>{
    FrostedGlassLevel.ultraThin: 'ultraThin',
    FrostedGlassLevel.thin: 'thin',
    FrostedGlassLevel.regular: 'regular',
    FrostedGlassLevel.thick: 'thick',
    FrostedGlassLevel.ultraThick: 'ultraThick',
  };

  static const Map<FrostedGlassTone, String> _toneLabels =
      <FrostedGlassTone, String>{
    FrostedGlassTone.auto: 'auto',
    FrostedGlassTone.light: 'light',
    FrostedGlassTone.dark: 'dark',
  };

  static const Map<FrostedGlassElevation, String> _elevationLabels =
      <FrostedGlassElevation, String>{
    FrostedGlassElevation.none: 'none',
    FrostedGlassElevation.floating: 'floating',
    FrostedGlassElevation.lifted: 'lifted',
  };

  @override
  Widget build(BuildContext context) {
    return FrostedGlass(
      level: FrostedGlassLevel.thick,
      borderRadius: BorderRadius.circular(FrostedRadius.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.sp3,
        vertical: FrostedSpacing.sp3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _AxisRow<FrostedGlassLevel>(
            label: 'Level',
            values: FrostedGlassLevel.values,
            labels: _levelLabels,
            selected: level,
            onChanged: onLevelChanged,
          ),
          const SizedBox(height: FrostedSpacing.sp2),
          _AxisRow<FrostedGlassTone>(
            label: 'Tone',
            values: FrostedGlassTone.values,
            labels: _toneLabels,
            selected: tone,
            onChanged: onToneChanged,
          ),
          const SizedBox(height: FrostedSpacing.sp2),
          _AxisRow<FrostedGlassElevation>(
            label: 'Shadow',
            values: FrostedGlassElevation.values,
            labels: _elevationLabels,
            selected: elevation,
            onChanged: onElevationChanged,
          ),
        ],
      ),
    );
  }
}

class _AxisRow<T> extends StatelessWidget {
  const _AxisRow({
    required this.label,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final Map<T, String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: FrostedTypeScale.labelMedium
                .copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: FrostedSpacing.sp1,
            runSpacing: FrostedSpacing.sp1,
            children: <Widget>[
              for (final T v in values)
                _ChipChoice(
                  label: labels[v]!,
                  selected: v == selected,
                  onTap: () => onChanged(v),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipChoice extends StatelessWidget {
  const _ChipChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.sp3,
          vertical: FrostedSpacing.sp1,
        ),
        decoration: BoxDecoration(
          color: selected
              ? cs.onSurface.withValues(alpha: 0.18)
              : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(FrostedRadius.full),
        ),
        child: Text(
          label,
          style: FrostedTypeScale.labelMedium.copyWith(
            color: cs.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SampleTabBar extends StatelessWidget {
  const _SampleTabBar();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 64,
      child: Row(
        children: <Widget>[
          Expanded(
            child: _TabItem(
              icon: Icons.home_outlined,
              label: 'Home',
              selected: true,
              color: cs.onSurface,
            ),
          ),
          Expanded(
            child: _TabItem(
              icon: Icons.search,
              label: 'Search',
              color: cs.onSurface,
            ),
          ),
          Expanded(
            child: _TabItem(
              icon: Icons.bookmark_outline,
              label: 'Library',
              color: cs.onSurface,
            ),
          ),
          Expanded(
            child: _TabItem(
              icon: Icons.person_outline,
              label: 'Me',
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.color,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color tint = selected ? color : color.withValues(alpha: 0.55);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: tint, size: 22),
        const SizedBox(height: 2),
        Text(
          label,
          style: FrostedTypeScale.labelSmall.copyWith(color: tint),
        ),
      ],
    );
  }
}

class _ChromePill extends StatelessWidget {
  const _ChromePill({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FrostedGlass(
        level: FrostedGlassLevel.regular,
        borderRadius: BorderRadius.circular(FrostedRadius.full),
        padding: const EdgeInsets.all(FrostedSpacing.sp3),
        child: child,
      ),
    );
  }
}
