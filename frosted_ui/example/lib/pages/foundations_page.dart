import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../theme_controller.dart';
import '../widgets/section.dart';

class FoundationsPage extends StatelessWidget {
  const FoundationsPage({required this.controller, super.key});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        return ListView(
          padding: EdgeInsets.fromLTRB(
            FrostedSpacing.sp4,
            FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
            FrostedSpacing.sp4,
            FrostedSpacing.sp7,
          ),
          children: <Widget>[
            _ThemeControls(controller: controller),
            const SizedBox(height: FrostedSpacing.sp6),
            const Section(
              title: 'Type scale',
              child: _TypeScaleSpecimen(),
            ),
            const SizedBox(height: FrostedSpacing.sp6),
            const Section(
              title: 'Spacing',
              child: _SpacingSpecimen(),
            ),
            const SizedBox(height: FrostedSpacing.sp6),
            const Section(
              title: 'Radii',
              child: _RadiusSpecimen(),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeControls extends StatelessWidget {
  const _ThemeControls({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Seed color', style: text.labelMedium),
        const SizedBox(height: FrostedSpacing.sp2),
        Wrap(
          spacing: FrostedSpacing.sp2,
          children: <Widget>[
            for (final SeedOption option in ThemeController.seedOptions)
              ChoiceChip(
                label: Text(option.label),
                avatar: CircleAvatar(backgroundColor: option.color, radius: 8),
                selected: controller.seedColor == option.color,
                onSelected: (_) => controller.setSeed(option.color),
              ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        Text('Brightness', style: text.labelMedium),
        const SizedBox(height: FrostedSpacing.sp2),
        SegmentedButton<ThemeMode>(
          segments: const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto_outlined),
            ),
          ],
          selected: <ThemeMode>{controller.mode},
          onSelectionChanged: (Set<ThemeMode> selection) =>
              controller.setMode(selection.first),
        ),
      ],
    );
  }
}

class _TypeScaleSpecimen extends StatelessWidget {
  const _TypeScaleSpecimen();

  @override
  Widget build(BuildContext context) {
    final List<_TypeRow> rows = <_TypeRow>[
      _TypeRow('Display large', FrostedTypeScale.displayLarge),
      _TypeRow('Display medium', FrostedTypeScale.displayMedium),
      _TypeRow('Display small', FrostedTypeScale.displaySmall),
      _TypeRow('Headline large', FrostedTypeScale.headlineLarge),
      _TypeRow('Headline medium', FrostedTypeScale.headlineMedium),
      _TypeRow('Headline small', FrostedTypeScale.headlineSmall),
      _TypeRow('Title large', FrostedTypeScale.titleLarge),
      _TypeRow('Title medium', FrostedTypeScale.titleMedium),
      _TypeRow('Title small', FrostedTypeScale.titleSmall),
      _TypeRow('Body large', FrostedTypeScale.bodyLarge),
      _TypeRow('Body medium', FrostedTypeScale.bodyMedium),
      _TypeRow('Body small', FrostedTypeScale.bodySmall),
      _TypeRow('Label large', FrostedTypeScale.labelLarge),
      _TypeRow('Label medium', FrostedTypeScale.labelMedium),
      _TypeRow('Label small', FrostedTypeScale.labelSmall),
    ];
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final _TypeRow row in rows) ...<Widget>[
          Text(
            row.label,
            style: FrostedTypeScale.labelSmall
                .copyWith(color: onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: FrostedSpacing.sp1),
          Text(
            'The quick brown fox 1234',
            style: row.style.copyWith(color: onSurface),
          ),
          const SizedBox(height: FrostedSpacing.sp4),
        ],
      ],
    );
  }
}

class _TypeRow {
  const _TypeRow(this.label, this.style);

  final String label;
  final TextStyle style;
}

class _SpacingSpecimen extends StatelessWidget {
  const _SpacingSpecimen();

  static const List<({String label, double value})> _items = <({
    String label,
    double value
  })>[
    (label: 'sp1', value: FrostedSpacing.sp1),
    (label: 'sp2', value: FrostedSpacing.sp2),
    (label: 'sp3', value: FrostedSpacing.sp3),
    (label: 'sp4', value: FrostedSpacing.sp4),
    (label: 'sp5', value: FrostedSpacing.sp5),
    (label: 'sp6', value: FrostedSpacing.sp6),
    (label: 'sp7', value: FrostedSpacing.sp7),
    (label: 'sp8', value: FrostedSpacing.sp8),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final ({String label, double value}) item in _items) ...<Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 56,
                child: Text(
                  item.label,
                  style: FrostedTypeScale.labelMedium
                      .copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              Container(
                width: item.value,
                height: 12,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(FrostedRadius.xs),
                ),
              ),
              const SizedBox(width: FrostedSpacing.sp2),
              Text(
                '${item.value.toInt()} dp',
                style: FrostedTypeScale.bodySmall
                    .copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: FrostedSpacing.sp2),
        ],
      ],
    );
  }
}

class _RadiusSpecimen extends StatelessWidget {
  const _RadiusSpecimen();

  static const List<({String label, double value})> _items = <({
    String label,
    double value
  })>[
    (label: 'xs', value: FrostedRadius.xs),
    (label: 'sm', value: FrostedRadius.sm),
    (label: 'md', value: FrostedRadius.md),
    (label: 'lg', value: FrostedRadius.lg),
    (label: 'xl', value: FrostedRadius.xl),
    (label: 'xxl', value: FrostedRadius.xxl),
    (label: 'full', value: FrostedRadius.full),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: FrostedSpacing.sp3,
      runSpacing: FrostedSpacing.sp3,
      children: <Widget>[
        for (final ({String label, double value}) item in _items)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(item.value),
                ),
              ),
              const SizedBox(height: FrostedSpacing.sp1),
              Text(
                item.label,
                style: FrostedTypeScale.labelSmall
                    .copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
      ],
    );
  }
}

