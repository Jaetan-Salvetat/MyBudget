import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_chart_tokens.dart';
import '../../foundations/frosted_type_scale.dart';
import 'frosted_chart_dot.dart';

@immutable
class FrostedLegendEntry {
  const FrostedLegendEntry({required this.color, required this.label});

  final Color color;
  final String label;
}

class FrostedChartLegend extends StatelessWidget {
  const FrostedChartLegend({
    required this.entries,
    this.trailing,
    this.showDivider = true,
    this.labelStyle,
    super.key,
  });

  final List<FrostedLegendEntry> entries;
  final Widget? trailing;
  final bool showDivider;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle style =
        labelStyle ??
        FrostedTypeScale.labelSmall.copyWith(color: cs.onSurfaceVariant);

    return Container(
      padding: showDivider
          ? const EdgeInsets.only(top: FrostedChartTokens.legendTopPadding)
          : EdgeInsets.zero,
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant,
                  width: FrostedChartTokens.dividerThickness,
                ),
              ),
            )
          : null,
      child: Row(
        children: <Widget>[
          for (int index = 0; index < entries.length; index++) ...<Widget>[
            if (index > 0)
              const SizedBox(width: FrostedChartTokens.legendEntryGap),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FrostedChartDot(
                  color: entries[index].color,
                  size: FrostedChartTokens.legendDotSize,
                  radius: FrostedChartTokens.legendDotRadius,
                ),
                const SizedBox(width: 5),
                Text(entries[index].label, style: style),
              ],
            ),
          ],
          if (trailing != null) ...<Widget>[
            const Spacer(),
            Flexible(
              child: DefaultTextStyle.merge(style: style, child: trailing!),
            ),
          ],
        ],
      ),
    );
  }
}
