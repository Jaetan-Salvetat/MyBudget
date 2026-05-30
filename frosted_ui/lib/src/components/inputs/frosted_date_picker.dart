import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../../theme/frosted_tokens.dart';
import '../actions/frosted_button.dart';
import '../overlays/frosted_scrim.dart';
import 'frosted_calendar.dart';
import 'frosted_picker_field.dart';

/// Opens the Frosted date picker — a glass shell with the M3 Expressive
/// calendar flow (headline, month/year navigation, year grid), rendered with
/// Frosted interactions instead of Material's.
///
/// Returns the picked [DateTime], or null if dismissed.
Future<DateTime?> showFrostedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final ThemeData theme = Theme.of(context);
  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (BuildContext context, Animation<double> _,
            Animation<double> _) =>
        Theme(
      data: theme,
      child: _DatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    ),
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

class _DatePickerDialog extends StatefulWidget {
  const _DatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late DateTime _selected = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final MaterialLocalizations l10n = MaterialLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.sp6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainer.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(FrostedRadius.xl),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: context.frostedTokens.glass.liftedShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(FrostedSpacing.sp5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Sélectionner une date',
                      style: FrostedTypeScale.labelMedium
                          .copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: FrostedSpacing.sp1),
                    Text(
                      l10n.formatMediumDate(_selected),
                      style: FrostedTypeScale.headlineSmall
                          .copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: FrostedSpacing.sp4),
                    FrostedCalendar(
                      selected: _selected,
                      firstDate: widget.firstDate,
                      lastDate: widget.lastDate,
                      onChanged: (DateTime d) => setState(() => _selected = d),
                    ),
                    const SizedBox(height: FrostedSpacing.sp4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        FrostedButton.text(
                          label: 'Annuler',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: FrostedSpacing.sp2),
                        FrostedButton.filled(
                          label: 'OK',
                          onPressed: () =>
                              Navigator.of(context).pop(_selected),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A field that displays the selected date and opens [showFrostedDatePicker]
/// on tap.
class FrostedDateField extends StatelessWidget {
  const FrostedDateField({
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    required this.format,
    this.label,
    this.hintText,
    this.enabled = true,
    this.glass = false,
    super.key,
  });

  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  /// Formats the selected [value] for display (e.g. via `intl`'s DateFormat).
  final String Function(DateTime date) format;

  final String? label;
  final String? hintText;
  final bool enabled;
  final bool glass;

  Future<void> _pick(BuildContext context) async {
    final DateTime? picked = await showFrostedDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FrostedPickerField(
      label: label,
      hintText: hintText,
      icon: Icons.calendar_today_outlined,
      text: value == null ? null : format(value!),
      enabled: enabled,
      glass: glass,
      onTap: () => _pick(context),
    );
  }
}
