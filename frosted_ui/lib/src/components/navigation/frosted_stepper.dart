import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../actions/_interactive_surface.dart';
import 'frosted_step.dart';

class FrostedStepper extends StatelessWidget {
  const FrostedStepper({
    required this.steps,
    required this.currentStep,
    this.onStepTapped,
    this.axis = Axis.horizontal,
    super.key,
  });

  final List<FrostedStep> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return axis == Axis.horizontal
        ? _HorizontalStepper(
            steps: steps,
            currentStep: currentStep,
            onStepTapped: onStepTapped,
          )
        : _VerticalStepper(
            steps: steps,
            currentStep: currentStep,
            onStepTapped: onStepTapped,
          );
  }
}

class _HorizontalStepper extends StatelessWidget {
  const _HorizontalStepper({
    required this.steps,
    required this.currentStep,
    required this.onStepTapped,
  });

  final List<FrostedStep> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (int i = 0; i < steps.length; i++) ...<Widget>[
              _StepCircle(
                index: i,
                state: _stateFor(i),
                onTap: onStepTapped == null ? null : () => onStepTapped!(i),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < currentStep ? cs.primary : cs.outlineVariant,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp2),
        Row(
          children: <Widget>[
            for (int i = 0; i < steps.length; i++) ...<Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      steps[i].title,
                      style: FrostedTypeScale.labelMedium.copyWith(
                        color: i == currentStep
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                        fontWeight: i == currentStep
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  _StepState _stateFor(int i) {
    if (i < currentStep) return _StepState.completed;
    if (i == currentStep) return _StepState.active;
    return _StepState.pending;
  }
}

class _VerticalStepper extends StatelessWidget {
  const _VerticalStepper({
    required this.steps,
    required this.currentStep,
    required this.onStepTapped,
  });

  final List<FrostedStep> steps;
  final int currentStep;
  final ValueChanged<int>? onStepTapped;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                children: <Widget>[
                  _StepCircle(
                    index: i,
                    state: _stateFor(i),
                    onTap: onStepTapped == null ? null : () => onStepTapped!(i),
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: FrostedSpacing.sp6,
                      color: i < currentStep ? cs.primary : cs.outlineVariant,
                    ),
                ],
              ),
              const SizedBox(width: FrostedSpacing.sp3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: FrostedSpacing.sp1,
                    bottom: FrostedSpacing.sp4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        steps[i].title,
                        style: FrostedTypeScale.titleSmall.copyWith(
                          color: i == currentStep
                              ? cs.onSurface
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      if (steps[i].subtitle != null) ...<Widget>[
                        const SizedBox(height: FrostedSpacing.sp1),
                        Text(
                          steps[i].subtitle!,
                          style: FrostedTypeScale.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  _StepState _stateFor(int i) {
    if (i < currentStep) return _StepState.completed;
    if (i == currentStep) return _StepState.active;
    return _StepState.pending;
  }
}

enum _StepState { completed, active, pending }

const double _kCircleSize = 28;

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.state,
    required this.onTap,
  });

  final int index;
  final _StepState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = switch (state) {
      _StepState.completed => cs.primary,
      _StepState.active => cs.primaryContainer,
      _StepState.pending => cs.surfaceContainerHigh,
    };
    final Color fg = switch (state) {
      _StepState.completed => cs.onPrimary,
      _StepState.active => cs.onPrimaryContainer,
      _StepState.pending => cs.onSurfaceVariant,
    };

    final Widget glyph = Center(
      child: state == _StepState.completed
          ? Icon(Icons.check, size: 16, color: fg)
          : Text(
              '${index + 1}',
              style: FrostedTypeScale.labelMedium.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
    );

    Widget circle(Widget content) => Container(
      width: _kCircleSize,
      height: _kCircleSize,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: content,
    );

    if (onTap == null) return circle(glyph);
    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: '${index + 1}',
      builder: (BuildContext context, InteractionStates s) =>
          circle(s.ink(glyph)),
    );
  }
}
