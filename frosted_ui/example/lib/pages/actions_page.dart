import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../widgets/section.dart';

class ActionsPage extends StatelessWidget {
  const ActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
        FrostedSpacing.sp4,
        FrostedSpacing.sp7,
      ),
      children: const <Widget>[
        Section(title: 'Buttons', child: _ButtonsDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Icon buttons', child: _IconButtonsDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Shape morphing', child: _ShapeMorphingDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'FAB', child: _FabDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Chips', child: _ChipsDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Switch', child: _SwitchDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Checkbox', child: _CheckboxDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Radio', child: _RadioDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Toggle buttons', child: _ToggleButtonsDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Split button', child: _SplitButtonDemo()),
      ],
    );
  }
}

class _ButtonsDemo extends StatelessWidget {
  const _ButtonsDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: FrostedSpacing.sp2,
          runSpacing: FrostedSpacing.sp2,
          children: <Widget>[
            FrostedButton.filled(label: 'Filled', onPressed: () {}),
            FrostedButton.tonal(label: 'Tonal', onPressed: () {}),
            FrostedButton.outlined(label: 'Outlined', onPressed: () {}),
            FrostedButton.text(label: 'Text', onPressed: () {}),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        Wrap(
          spacing: FrostedSpacing.sp2,
          runSpacing: FrostedSpacing.sp2,
          children: <Widget>[
            FrostedButton.filled(
              label: 'Save',
              icon: Icons.check,
              onPressed: () {},
            ),
            FrostedButton.tonal(
              label: 'Continue',
              trailingIcon: Icons.arrow_forward,
              onPressed: () {},
            ),
            FrostedButton.outlined(
              label: 'Disabled',
              onPressed: null,
            ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        FrostedButton.filled(
          label: 'Expanded',
          icon: Icons.bolt,
          expanded: true,
          onPressed: () {},
        ),
      ],
    );
  }
}

/// Every variant in both resting forms. Press one and it morphs into the
/// other form for as long as it is held — pill flattens, rounded rounds out.
class _ShapeMorphingDemo extends StatelessWidget {
  const _ShapeMorphingDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final FrostedShape shape in FrostedShape.values) ...<Widget>[
          _ShapeLabel(shape: shape),
          const SizedBox(height: FrostedSpacing.sp2),
          Wrap(
            spacing: FrostedSpacing.sp2,
            runSpacing: FrostedSpacing.sp2,
            children: <Widget>[
              FrostedButton.filled(
                label: 'Filled',
                shape: shape,
                onPressed: () {},
              ),
              FrostedButton.tonal(
                label: 'Tonal',
                shape: shape,
                onPressed: () {},
              ),
              FrostedButton.outlined(
                label: 'Outlined',
                shape: shape,
                onPressed: () {},
              ),
              FrostedButton.text(
                label: 'Text',
                shape: shape,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: FrostedSpacing.sp2),
          Wrap(
            spacing: FrostedSpacing.sp2,
            runSpacing: FrostedSpacing.sp2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              FrostedIconButton.standard(
                icon: Icons.favorite_outline,
                shape: shape,
                tooltip: 'Standard',
                onPressed: () {},
              ),
              FrostedIconButton.filled(
                icon: Icons.bookmark_outline,
                shape: shape,
                tooltip: 'Filled',
                onPressed: () {},
              ),
              FrostedIconButton.tonal(
                icon: Icons.notifications_outlined,
                shape: shape,
                tooltip: 'Tonal',
                onPressed: () {},
              ),
              FrostedIconButton.outlined(
                icon: Icons.share_outlined,
                shape: shape,
                tooltip: 'Outlined',
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: FrostedSpacing.sp4),
        ],
      ],
    );
  }
}

class _ShapeLabel extends StatelessWidget {
  const _ShapeLabel({required this.shape});

  final FrostedShape shape;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Text(
      switch (shape) {
        FrostedShape.pill => 'pill — presses into rounded',
        FrostedShape.rounded => 'rounded — presses into pill',
      },
      style: FrostedTypeScale.labelMedium.copyWith(
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

class _IconButtonsDemo extends StatefulWidget {
  const _IconButtonsDemo();

  @override
  State<_IconButtonsDemo> createState() => _IconButtonsDemoState();
}

class _IconButtonsDemoState extends State<_IconButtonsDemo> {
  bool _standardSel = false;
  bool _filledSel = true;
  bool _tonalSel = false;
  bool _outlinedSel = false;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: FrostedSpacing.sp2,
      runSpacing: FrostedSpacing.sp2,
      children: <Widget>[
        FrostedIconButton.standard(
          icon: Icons.favorite_outline,
          selectedIcon: Icons.favorite,
          selected: _standardSel,
          tooltip: 'Like',
          onPressed: () => setState(() => _standardSel = !_standardSel),
        ),
        FrostedIconButton.filled(
          icon: Icons.bookmark_outline,
          selectedIcon: Icons.bookmark,
          selected: _filledSel,
          tooltip: 'Save',
          onPressed: () => setState(() => _filledSel = !_filledSel),
        ),
        FrostedIconButton.tonal(
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications,
          selected: _tonalSel,
          tooltip: 'Notify',
          onPressed: () => setState(() => _tonalSel = !_tonalSel),
        ),
        FrostedIconButton.outlined(
          icon: Icons.share_outlined,
          selected: _outlinedSel,
          tooltip: 'Share',
          onPressed: () => setState(() => _outlinedSel = !_outlinedSel),
        ),
        FrostedIconButton.standard(
          icon: Icons.delete_outline,
          tooltip: 'Disabled',
          onPressed: null,
        ),
      ],
    );
  }
}

class _FabDemo extends StatelessWidget {
  const _FabDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: FrostedSpacing.sp3,
      runSpacing: FrostedSpacing.sp3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        FrostedFab.small(icon: Icons.add, onPressed: () {}),
        FrostedFab.regular(icon: Icons.edit, onPressed: () {}),
        FrostedFab.large(icon: Icons.bolt, onPressed: () {}),
        FrostedFab.extended(
          icon: Icons.add,
          label: 'New task',
          onPressed: () {},
        ),
        FrostedFab.regular(
          icon: Icons.mic,
          tonal: true,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _ChipsDemo extends StatefulWidget {
  const _ChipsDemo();

  @override
  State<_ChipsDemo> createState() => _ChipsDemoState();
}

class _ChipsDemoState extends State<_ChipsDemo> {
  final Set<String> _filters = <String>{'Design'};
  final List<String> _tags = <String>['flutter', 'dart', 'design'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SubLabel('Assist'),
        Wrap(
          spacing: FrostedSpacing.sp2,
          runSpacing: FrostedSpacing.sp2,
          children: <Widget>[
            FrostedChip.assist(
              label: 'Settings',
              icon: Icons.settings_outlined,
              onTap: () {},
            ),
            FrostedChip.assist(
              label: 'Share',
              icon: Icons.share_outlined,
              onTap: () {},
            ),
            FrostedChip.assist(label: 'Disabled', onTap: null),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _SubLabel('Filter'),
        Wrap(
          spacing: FrostedSpacing.sp2,
          runSpacing: FrostedSpacing.sp2,
          children: <Widget>[
            for (final String label in const <String>[
              'Design',
              'Engineering',
              'Culture',
              'Photo',
              'Travel',
            ])
              FrostedChip.filter(
                label: label,
                selected: _filters.contains(label),
                onSelected: (bool s) => setState(() {
                  if (s) {
                    _filters.add(label);
                  } else {
                    _filters.remove(label);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _SubLabel('Input'),
        Wrap(
          spacing: FrostedSpacing.sp2,
          runSpacing: FrostedSpacing.sp2,
          children: <Widget>[
            for (final String tag in _tags)
              FrostedChip.input(
                label: tag,
                avatar: const Icon(Icons.tag, size: 16),
                onDelete: () => setState(() => _tags.remove(tag)),
              ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _SubLabel('Suggestion'),
        Wrap(
          spacing: FrostedSpacing.sp2,
          runSpacing: FrostedSpacing.sp2,
          children: <Widget>[
            FrostedChip.suggestion(label: 'Tell me a joke', onTap: () {}),
            FrostedChip.suggestion(
              label: 'Write a haiku',
              onTap: () {},
            ),
            FrostedChip.suggestion(
              label: 'Plan a trip',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: FrostedSpacing.sp2),
      child: Text(
        text,
        style: FrostedTypeScale.labelSmall.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SwitchDemo extends StatefulWidget {
  const _SwitchDemo();

  @override
  State<_SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<_SwitchDemo> {
  bool _on = true;
  bool _off = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        FrostedSwitch(value: _on, onChanged: (bool v) => setState(() => _on = v)),
        const SizedBox(width: FrostedSpacing.sp4),
        FrostedSwitch(value: _off, onChanged: (bool v) => setState(() => _off = v)),
        const SizedBox(width: FrostedSpacing.sp4),
        const FrostedSwitch(value: true, onChanged: null),
        const SizedBox(width: FrostedSpacing.sp4),
        const FrostedSwitch(value: false, onChanged: null),
      ],
    );
  }
}

class _CheckboxDemo extends StatefulWidget {
  const _CheckboxDemo();

  @override
  State<_CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<_CheckboxDemo> {
  bool? _a = true;
  bool? _b = false;
  bool? _c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        FrostedCheckbox(value: _a, onChanged: (bool? v) => setState(() => _a = v)),
        FrostedCheckbox(value: _b, onChanged: (bool? v) => setState(() => _b = v)),
        FrostedCheckbox(
          value: _c,
          tristate: true,
          onChanged: (bool? v) => setState(() => _c = v),
        ),
        const FrostedCheckbox(value: true, onChanged: null),
        const FrostedCheckbox(value: false, onChanged: null),
      ],
    );
  }
}

class _RadioDemo extends StatefulWidget {
  const _RadioDemo();

  @override
  State<_RadioDemo> createState() => _RadioDemoState();
}

class _RadioDemoState extends State<_RadioDemo> {
  String _group = 'option-a';

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final String key in const <String>[
          'option-a',
          'option-b',
          'option-c',
        ])
          Row(
            children: <Widget>[
              FrostedRadio<String>(
                value: key,
                groupValue: _group,
                onChanged: (String? v) =>
                    setState(() => _group = v ?? _group),
              ),
              Text(
                key,
                style: FrostedTypeScale.bodyMedium
                    .copyWith(color: cs.onSurface),
              ),
            ],
          ),
      ],
    );
  }
}

class _ToggleButtonsDemo extends StatefulWidget {
  const _ToggleButtonsDemo();

  @override
  State<_ToggleButtonsDemo> createState() => _ToggleButtonsDemoState();
}

class _ToggleButtonsDemoState extends State<_ToggleButtonsDemo> {
  Set<int> _singleSelected = <int>{1};
  Set<int> _multiSelected = <int>{0, 2};
  Set<int> _standardSelected = <int>{0};
  Set<int> _standardMultiSelected = <int>{1};

  static const List<FrostedToggleItem> _formatItems = <FrostedToggleItem>[
    FrostedToggleItem(icon: Icons.format_bold, tooltip: 'Bold'),
    FrostedToggleItem(icon: Icons.format_italic, tooltip: 'Italic'),
    FrostedToggleItem(icon: Icons.format_underline, tooltip: 'Underline'),
  ];

  static const List<FrostedToggleItem> _alignItems = <FrostedToggleItem>[
    FrostedToggleItem(
      icon: Icons.format_align_left,
      label: 'Left',
    ),
    FrostedToggleItem(
      icon: Icons.format_align_center,
      label: 'Center',
    ),
    FrostedToggleItem(
      icon: Icons.format_align_right,
      label: 'Right',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SubLabel('Connected · single select'),
        FrostedToggleButtons.connected(
          items: _alignItems,
          selected: _singleSelected,
          onChanged: (Set<int> s) => setState(() => _singleSelected = s),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _SubLabel('Connected · multi select'),
        FrostedToggleButtons.connected(
          items: _formatItems,
          selected: _multiSelected,
          multiSelect: true,
          onChanged: (Set<int> s) => setState(() => _multiSelected = s),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _SubLabel('Standard · single select'),
        FrostedToggleButtons.standard(
          items: _alignItems,
          selected: _standardSelected,
          onChanged: (Set<int> s) => setState(() => _standardSelected = s),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _SubLabel('Standard · multi select'),
        FrostedToggleButtons.standard(
          items: _formatItems,
          selected: _standardMultiSelected,
          multiSelect: true,
          onChanged: (Set<int> s) =>
              setState(() => _standardMultiSelected = s),
        ),
      ],
    );
  }
}

class _SplitButtonDemo extends StatelessWidget {
  const _SplitButtonDemo();

  @override
  Widget build(BuildContext context) {
    final List<FrostedSplitMenuItem> menu = <FrostedSplitMenuItem>[
      FrostedSplitMenuItem(
        label: 'Save and continue',
        icon: Icons.arrow_forward,
        onTap: () {},
      ),
      FrostedSplitMenuItem(
        label: 'Save as draft',
        icon: Icons.drafts_outlined,
        onTap: () {},
      ),
      FrostedSplitMenuItem(
        label: 'Discard',
        icon: Icons.delete_outline,
        onTap: () {},
      ),
    ];
    return Wrap(
      spacing: FrostedSpacing.sp3,
      runSpacing: FrostedSpacing.sp3,
      children: <Widget>[
        FrostedSplitButton.filled(
          label: 'Save',
          icon: Icons.check,
          onPressed: () {},
          menuItems: menu,
        ),
        FrostedSplitButton.tonal(
          label: 'Export',
          icon: Icons.file_download_outlined,
          onPressed: () {},
          menuItems: menu,
        ),
        FrostedSplitButton.outlined(
          label: 'Share',
          icon: Icons.share_outlined,
          onPressed: () {},
          menuItems: menu,
        ),
      ],
    );
  }
}
