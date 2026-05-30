import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/_interactive_surface.dart';
import '../actions/frosted_button.dart';
import '../actions/frosted_icon_button.dart';
import '../overlays/frosted_scrim.dart';
import 'frosted_clock_dial.dart';
import 'frosted_picker_field.dart';

/// Opens the Frosted time picker — a glass shell with the M3 flow: two
/// HH:MM selectors, a circular clock dial, and a toggle to the keyboard
/// (TimeInput) mode. 24-hour.
///
/// Returns the picked [TimeOfDay], or null if dismissed.
Future<TimeOfDay?> showFrostedTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  final ThemeData theme = Theme.of(context);
  return showGeneralDialog<TimeOfDay>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (BuildContext context, Animation<double> _,
            Animation<double> _) =>
        Theme(data: theme, child: _TimePickerDialog(initialTime: initialTime)),
    transitionBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondary,
      Widget child,
    ) {
      final CurvedAnimation curve = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.32, 0.72, 0, 1),
      );
      return Stack(
        children: <Widget>[
          FrostedScrim(
            animation: curve,
            onDismiss: () => Navigator.of(context).maybePop(),
          ),
          FadeTransition(
            opacity: curve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(curve),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

class _TimePickerDialog extends StatefulWidget {
  const _TimePickerDialog({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late int _hour = widget.initialTime.hour;
  late int _minute = widget.initialTime.minute;
  FrostedClockUnit _unit = FrostedClockUnit.hour;
  bool _keyboard = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.sp6),
        child: Material(
          type: MaterialType.transparency,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(FrostedRadius.xl),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: context.frostedTokens.glass.liftedShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(FrostedSpacing.sp5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Sélectionner l'heure",
                    style: FrostedTypeScale.labelMedium
                        .copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: FrostedSpacing.sp4),
                  _Selectors(
                    hour: _hour,
                    minute: _minute,
                    unit: _unit,
                    keyboard: _keyboard,
                    onUnit: (FrostedClockUnit u) => setState(() => _unit = u),
                    onHour: (int h) => setState(() => _hour = h),
                    onMinute: (int m) => setState(() => _minute = m),
                  ),
                  if (!_keyboard) ...<Widget>[
                    const SizedBox(height: FrostedSpacing.sp5),
                    Center(
                      child: FrostedClockDial(
                        unit: _unit,
                        hour: _hour,
                        minute: _minute,
                        onChanged: (int v) => setState(() {
                          if (_unit == FrostedClockUnit.hour) {
                            _hour = v;
                          } else {
                            _minute = v;
                          }
                        }),
                      ),
                    ),
                  ],
                  const SizedBox(height: FrostedSpacing.sp4),
                  Row(
                    children: <Widget>[
                      FrostedIconButton.standard(
                        icon: _keyboard
                            ? Icons.schedule_outlined
                            : Icons.keyboard_outlined,
                        tooltip: _keyboard ? 'Cadran' : 'Saisie clavier',
                        onPressed: () =>
                            setState(() => _keyboard = !_keyboard),
                      ),
                      const Spacer(),
                      FrostedButton.text(
                        label: 'Annuler',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: FrostedSpacing.sp2),
                      FrostedButton.filled(
                        label: 'OK',
                        onPressed: () => Navigator.of(context).pop(
                          TimeOfDay(hour: _hour, minute: _minute),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Selectors extends StatelessWidget {
  const _Selectors({
    required this.hour,
    required this.minute,
    required this.unit,
    required this.keyboard,
    required this.onUnit,
    required this.onHour,
    required this.onMinute,
  });

  final int hour;
  final int minute;
  final FrostedClockUnit unit;
  final bool keyboard;
  final ValueChanged<FrostedClockUnit> onUnit;
  final ValueChanged<int> onHour;
  final ValueChanged<int> onMinute;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _Field(
          value: hour,
          active: unit == FrostedClockUnit.hour,
          keyboard: keyboard,
          onTap: () => onUnit(FrostedClockUnit.hour),
          onChanged: (int v) => onHour(v % 24),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp2),
          child: Text(
            ':',
            style: FrostedTypeScale.displaySmall.copyWith(color: cs.onSurface),
          ),
        ),
        _Field(
          value: minute,
          active: unit == FrostedClockUnit.minute,
          keyboard: keyboard,
          onTap: () => onUnit(FrostedClockUnit.minute),
          onChanged: (int v) => onMinute(v % 60),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.value,
    required this.active,
    required this.keyboard,
    required this.onTap,
    required this.onChanged,
  });

  final int value;
  final bool active;
  final bool keyboard;
  final VoidCallback onTap;
  final ValueChanged<int> onChanged;

  static const double _w = 96;
  static const double _h = 80;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = active ? cs.primaryContainer : cs.surfaceContainerHighest;
    final Color fg = active ? cs.onPrimaryContainer : cs.onSurface;
    final String text = value.toString().padLeft(2, '0');

    if (keyboard) {
      return SizedBox(
        width: _w,
        height: _h,
        child: TextField(
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 2,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (String s) {
            final int? v = int.tryParse(s);
            if (v != null) onChanged(v);
          },
          onTap: onTap,
          style: FrostedTypeScale.displaySmall.copyWith(color: fg),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: bg,
            hintText: text,
            hintStyle: FrostedTypeScale.displaySmall
                .copyWith(color: fg.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FrostedRadius.lg),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
    }

    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: text,
      semanticsSelected: active,
      shape: (_) => BorderRadius.circular(FrostedRadius.lg),
      builder: (BuildContext context, InteractionStates s) {
        final double overlay = s.pressed
            ? 0.12
            : s.hovered
                ? 0.08
                : 0;
        return Container(
          width: _w,
          height: _h,
          decoration: BoxDecoration(
            color: overlay == 0
                ? bg
                : Color.alphaBlend(fg.withValues(alpha: overlay), bg),
            borderRadius: BorderRadius.circular(FrostedRadius.lg),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: FrostedTypeScale.displaySmall.copyWith(color: fg),
          ),
        );
      },
    );
  }
}

/// A field that displays the selected time and opens [showFrostedTimePicker]
/// on tap.
class FrostedTimeField extends StatelessWidget {
  const FrostedTimeField({
    required this.value,
    required this.onChanged,
    this.label,
    this.hintText,
    this.enabled = true,
    this.glass = false,
    super.key,
  });

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final String? label;
  final String? hintText;
  final bool enabled;
  final bool glass;

  Future<void> _pick(BuildContext context) async {
    final TimeOfDay? picked = await showFrostedTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FrostedPickerField(
      label: label,
      hintText: hintText,
      icon: Icons.schedule_outlined,
      text: value?.format(context),
      enabled: enabled,
      glass: glass,
      onTap: () => _pick(context),
    );
  }
}
