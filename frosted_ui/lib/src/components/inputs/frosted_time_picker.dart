import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../actions/_interactive_surface.dart';
import '../actions/frosted_button.dart';
import '../actions/frosted_icon_button.dart';
import '../overlays/frosted_dialog.dart';
import 'frosted_clock_dial.dart';
import 'frosted_picker_field.dart';

Future<TimeOfDay?> showFrostedTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showFrostedDialog<TimeOfDay>(
    context: context,
    builder: (BuildContext context) =>
        _TimePickerDialog(initialTime: initialTime),
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
    return FrostedDialog(
      title: "Sélectionner l'heure",
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
        ],
      ),
      leadingAction: FrostedIconButton.standard(
        icon: _keyboard ? Icons.schedule_outlined : Icons.keyboard_outlined,
        tooltip: _keyboard ? 'Cadran' : 'Saisie clavier',
        onPressed: () => setState(() => _keyboard = !_keyboard),
      ),
      actions: <Widget>[
        FrostedButton.text(
          label: 'Annuler',
          onPressed: () => Navigator.of(context).pop(),
        ),
        FrostedButton.filled(
          label: 'OK',
          onPressed: () => Navigator.of(
            context,
          ).pop(TimeOfDay(hour: _hour, minute: _minute)),
        ),
      ],
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
            hintStyle: FrostedTypeScale.displaySmall.copyWith(
              color: fg.withValues(alpha: 0.5),
            ),
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
      builder: (BuildContext context, InteractionStates s) {
        final double overlay = s.pressed
            ? 0.12
            : s.hovered
            ? 0.08
            : 0;
        return Container(
          width: _w,
          height: _h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: overlay == 0
                ? bg
                : Color.alphaBlend(fg.withValues(alpha: overlay), bg),
            borderRadius: BorderRadius.circular(FrostedRadius.lg),
          ),
          child: s.ink(
            Center(
              child: Text(
                text,
                style: FrostedTypeScale.displaySmall.copyWith(color: fg),
              ),
            ),
          ),
        );
      },
    );
  }
}

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
