import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/section.dart';

class IndicatorsPage extends StatelessWidget {
  const IndicatorsPage({super.key});

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
        Section(title: 'Linear progress', child: _LinearProgressDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Circular progress', child: _CircularProgressDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Continuous slider', child: _ContinuousSliderDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Discrete slider', child: _DiscreteSliderDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Centered slider', child: _CenteredSliderDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Range slider', child: _RangeSliderDemo()),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: FrostedSpacing.sp2),
      child: Text(
        label,
        style: FrostedTypeScale.labelSmall.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _LinearProgressDemo extends StatefulWidget {
  const _LinearProgressDemo();

  @override
  State<_LinearProgressDemo> createState() => _LinearProgressDemoState();
}

class _LinearProgressDemoState extends State<_LinearProgressDemo> {
  double _value = 0.45;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Caption('Determinate'),
        FrostedLinearProgress(value: _value),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Indeterminate'),
        const FrostedLinearProgress(),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Thickness 8'),
        FrostedLinearProgress(value: _value, thickness: 8),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Thickness 16'),
        FrostedLinearProgress(value: _value, thickness: 16),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Thickness 16 · indeterminate'),
        const FrostedLinearProgress(thickness: 16),
        const SizedBox(height: FrostedSpacing.sp5),
        const _Caption('Progress'),
        FrostedSlider(
          value: _value,
          onChanged: (double value) => setState(() => _value = value),
        ),
      ],
    );
  }
}

class _CircularProgressDemo extends StatefulWidget {
  const _CircularProgressDemo();

  @override
  State<_CircularProgressDemo> createState() => _CircularProgressDemoState();
}

class _CircularProgressDemoState extends State<_CircularProgressDemo> {
  double _value = 0.65;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Caption('Determinate · indeterminate'),
        Wrap(
          spacing: FrostedSpacing.sp5,
          runSpacing: FrostedSpacing.sp4,
          children: <Widget>[
            FrostedCircularProgress(value: _value),
            const FrostedCircularProgress(),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Sizes'),
        Wrap(
          spacing: FrostedSpacing.sp5,
          runSpacing: FrostedSpacing.sp4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FrostedCircularProgress(value: _value, size: 24, thickness: 3),
            FrostedCircularProgress(value: _value, size: 64),
            FrostedCircularProgress(value: _value, size: 96, thickness: 8),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp5),
        const _Caption('Progress'),
        FrostedSlider(
          value: _value,
          onChanged: (double value) => setState(() => _value = value),
        ),
      ],
    );
  }
}

class _ContinuousSliderDemo extends StatefulWidget {
  const _ContinuousSliderDemo();

  @override
  State<_ContinuousSliderDemo> createState() => _ContinuousSliderDemoState();
}

class _ContinuousSliderDemoState extends State<_ContinuousSliderDemo> {
  double _value = 0.4;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedSlider(
          value: _value,
          label: (_value * 100).round().toString(),
          onChanged: (double value) => setState(() => _value = value),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Disabled'),
        FrostedSlider(value: _value, onChanged: null),
      ],
    );
  }
}

class _DiscreteSliderDemo extends StatefulWidget {
  const _DiscreteSliderDemo();

  @override
  State<_DiscreteSliderDemo> createState() => _DiscreteSliderDemoState();
}

class _DiscreteSliderDemoState extends State<_DiscreteSliderDemo> {
  double _value = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedSlider(
          value: _value,
          max: 10,
          divisions: 10,
          label: _value.round().toString(),
          onChanged: (double value) => setState(() => _value = value),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Disabled'),
        FrostedSlider(
          value: _value,
          max: 10,
          divisions: 10,
          onChanged: null,
        ),
      ],
    );
  }
}

class _CenteredSliderDemo extends StatefulWidget {
  const _CenteredSliderDemo();

  @override
  State<_CenteredSliderDemo> createState() => _CenteredSliderDemoState();
}

class _CenteredSliderDemoState extends State<_CenteredSliderDemo> {
  double _continuous = 0.3;
  double _discrete = -2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedSlider(
          value: _continuous,
          min: -1,
          track: FrostedSliderTrack.centered,
          onChanged: (double value) => setState(() => _continuous = value),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Discrete'),
        FrostedSlider(
          value: _discrete,
          min: -5,
          max: 5,
          divisions: 10,
          label: _discrete.round().toString(),
          track: FrostedSliderTrack.centered,
          onChanged: (double value) => setState(() => _discrete = value),
        ),
      ],
    );
  }
}

class _RangeSliderDemo extends StatefulWidget {
  const _RangeSliderDemo();

  @override
  State<_RangeSliderDemo> createState() => _RangeSliderDemoState();
}

class _RangeSliderDemoState extends State<_RangeSliderDemo> {
  RangeValues _continuous = const RangeValues(200, 800);
  RangeValues _discrete = const RangeValues(4, 14);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedRangeSlider(
          values: _continuous,
          max: 1000,
          onChanged: (RangeValues values) =>
              setState(() => _continuous = values),
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        const _Caption('Discrete'),
        FrostedRangeSlider(
          values: _discrete,
          max: 20,
          divisions: 20,
          labels: RangeLabels(
            _discrete.start.round().toString(),
            _discrete.end.round().toString(),
          ),
          onChanged: (RangeValues values) => setState(() => _discrete = values),
        ),
      ],
    );
  }
}
