import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/loans/widgets/loan_detail_row.dart';

class LoanDetailInfoCard extends StatelessWidget {
  final String title;
  final List<LoanDetailRow> rows;

  const LoanDetailInfoCard({
    required this.title,
    required this.rows,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8, left: 4, right: 4),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.09 * 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        FrostedCard(
          margin: EdgeInsets.zero,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Column(children: rows),
        ),
      ],
    );
  }
}
