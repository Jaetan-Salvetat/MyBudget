import 'package:flutter/material.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../actions/_interactive_surface.dart';
import '../actions/frosted_icon_button.dart';

/// The month grid + year grid used inside the date picker, with Frosted
/// interactions (day/year cells are [InteractiveSurface]s, the selection is a
/// primary pill). Mirrors the M3 Expressive calendar flow: a navigable month
/// label that toggles a year picker, chevrons to step months.
///
/// Internal to the library — composed by the date picker dialog.
class FrostedCalendar extends StatefulWidget {
  const FrostedCalendar({
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    super.key,
  });

  final DateTime selected;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  State<FrostedCalendar> createState() => _FrostedCalendarState();
}

class _FrostedCalendarState extends State<FrostedCalendar> {
  late DateTime _visibleMonth = DateTime(
    widget.selected.year,
    widget.selected.month,
  );
  bool _yearMode = false;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime d) =>
      !d.isBefore(_dateOnly(widget.firstDate)) &&
      !d.isAfter(_dateOnly(widget.lastDate));

  void _step(int months) => setState(
    () => _visibleMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + months,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final MaterialLocalizations l10n = MaterialLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            _MonthLabel(
              label: l10n.formatMonthYear(_visibleMonth),
              expanded: _yearMode,
              onTap: () => setState(() => _yearMode = !_yearMode),
            ),
            const Spacer(),
            if (!_yearMode) ...<Widget>[
              FrostedIconButton.standard(
                icon: Icons.chevron_left,
                tooltip: 'Mois précédent',
                onPressed: () => _step(-1),
              ),
              FrostedIconButton.standard(
                icon: Icons.chevron_right,
                tooltip: 'Mois suivant',
                onPressed: () => _step(1),
              ),
            ],
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp2),
        SizedBox(
          height: 264,
          child: _yearMode ? _buildYearGrid(cs) : _buildMonthGrid(cs, l10n),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(ColorScheme cs, MaterialLocalizations l10n) {
    final int year = _visibleMonth.year;
    final int month = _visibleMonth.month;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final int leadingBlanks =
        (DateTime(year, month).weekday - DateTime.monday) % 7;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final String d in _weekdayLabels(l10n))
              Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: FrostedTypeScale.labelMedium.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp1),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
              for (int day = 1; day <= daysInMonth; day++)
                _DayCell(
                  day: day,
                  selected: _sameDay(
                    widget.selected,
                    DateTime(year, month, day),
                  ),
                  enabled: _inRange(DateTime(year, month, day)),
                  onTap: () => widget.onChanged(DateTime(year, month, day)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYearGrid(ColorScheme cs) {
    final int first = widget.firstDate.year;
    final int last = widget.lastDate.year;
    return GridView.count(
      crossAxisCount: 3,
      padding: EdgeInsets.zero,
      childAspectRatio: 2.2,
      children: <Widget>[
        for (int y = first; y <= last; y++)
          _YearCell(
            year: y,
            selected: y == _visibleMonth.year,
            onTap: () => setState(() {
              _visibleMonth = DateTime(y, _visibleMonth.month);
              _yearMode = false;
            }),
          ),
      ],
    );
  }

  List<String> _weekdayLabels(MaterialLocalizations l10n) {
    final List<String> narrow = l10n.narrowWeekdays;
    return <String>[
      for (int i = 0; i < 7; i++) narrow[(i + DateTime.monday) % 7],
    ];
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InteractiveSurface(
      onTap: onTap,
      semanticsLabel: label,
      builder: (BuildContext context, InteractionStates s) {
        final double overlay = s.pressed
            ? 0.12
            : s.focused
            ? 0.10
            : s.hovered
            ? 0.08
            : 0;
        return Container(
          decoration: BoxDecoration(
            color: overlay == 0
                ? Colors.transparent
                : cs.onSurface.withValues(alpha: overlay),
            borderRadius: BorderRadius.circular(FrostedRadius.full),
          ),
          child: s.ink(
            borderRadius: BorderRadius.circular(FrostedRadius.full),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedSpacing.sp3,
                vertical: FrostedSpacing.sp1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: FrostedTypeScale.titleMedium.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                  Icon(
                    expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = !enabled
        ? cs.onSurface.withValues(alpha: 0.38)
        : selected
        ? cs.onPrimary
        : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: InteractiveSurface(
        onTap: enabled ? onTap : null,
        semanticsLabel: '$day',
        semanticsSelected: selected,
        builder: (BuildContext context, InteractionStates s) {
          final double overlay = s.pressed
              ? 0.12
              : s.focused
              ? 0.10
              : s.hovered
              ? 0.08
              : 0;
          final Color base = selected ? cs.primary : Colors.transparent;
          final Color bg = overlay == 0
              ? base
              : Color.alphaBlend(
                  (selected ? cs.onPrimary : cs.onSurface).withValues(
                    alpha: overlay,
                  ),
                  base,
                );
          return Container(
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: s.ink(
              borderRadius: BorderRadius.circular(FrostedRadius.full),
              Center(
                child: Text(
                  '$day',
                  style: FrostedTypeScale.bodyMedium.copyWith(color: fg),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _YearCell extends StatelessWidget {
  const _YearCell({
    required this.year,
    required this.selected,
    required this.onTap,
  });

  final int year;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fg = selected ? cs.onPrimary : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.all(FrostedSpacing.sp1),
      child: InteractiveSurface(
        onTap: onTap,
        semanticsLabel: '$year',
        semanticsSelected: selected,
        builder: (BuildContext context, InteractionStates s) {
          final double overlay = s.pressed
              ? 0.12
              : s.focused
              ? 0.10
              : s.hovered
              ? 0.08
              : 0;
          final Color base = selected ? cs.primary : Colors.transparent;
          final Color bg = overlay == 0
              ? base
              : Color.alphaBlend(
                  (selected ? cs.onPrimary : cs.onSurface).withValues(
                    alpha: overlay,
                  ),
                  base,
                );
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(FrostedRadius.full),
            ),
            child: s.ink(
              borderRadius: BorderRadius.circular(FrostedRadius.full),
              Center(
                child: Text(
                  '$year',
                  style: FrostedTypeScale.bodyLarge.copyWith(color: fg),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
