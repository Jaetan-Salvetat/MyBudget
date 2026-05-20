import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

class LoanDetailKpiCard extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String? leftHint;
  final String rightLabel;
  final String rightValue;
  final String? rightHint;

  const LoanDetailKpiCard({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.leftHint,
    this.rightHint,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FrostedCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Stat(label: leftLabel, value: leftValue, hint: leftHint),
            ),
            VerticalDivider(
              width: 28,
              thickness: 1,
              color: scheme.onSurface.withValues(alpha: 0.08),
            ),
            Expanded(
              child:
                  _Stat(label: rightLabel, value: rightValue, hint: rightHint),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;

  const _Stat({required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            height: 14 / 11,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            height: 20 / 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: TextStyle(
              fontSize: 10,
              height: 14 / 10,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}
