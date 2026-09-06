import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';

class RevenueGroupByChip extends StatelessWidget {
  const RevenueGroupByChip({
    required this.axis,
    required this.onTap,
    super.key,
  });
  final RevenueGroupBy axis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.06),
          border: Border.all(
            width: 1,
            color: scheme.onSurface.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.workspaces_rounded, size: 14, color: scheme.onSurface),
            const SizedBox(width: 5),
            Text(
              axis.label,
              style: TextStyle(
                fontSize: 12.5,
                height: 16 / 12.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Symbols.expand_more_rounded,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
