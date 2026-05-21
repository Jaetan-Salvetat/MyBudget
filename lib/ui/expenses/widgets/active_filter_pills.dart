import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ActiveFilterPill {
  final String id;
  final String label;
  final VoidCallback onRemove;

  const ActiveFilterPill({
    required this.id,
    required this.label,
    required this.onRemove,
  });
}

class ActiveFilterPills extends StatelessWidget {
  final List<ActiveFilterPill> pills;
  final VoidCallback onReset;

  const ActiveFilterPills({
    required this.pills,
    required this.onReset,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (pills.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final pill in pills)
          Container(
            padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pill.label,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: pill.onRemove,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Symbols.close_rounded,
                      size: 11,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        TextButton(
          onPressed: onReset,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(0, 26),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Réinit.',
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
