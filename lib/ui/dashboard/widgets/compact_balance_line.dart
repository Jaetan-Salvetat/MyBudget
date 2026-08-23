import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';

/// The hero balance, reduced to one line. Stands in for the card while the
/// keyboard is up : the number has to stay readable above the input.
class CompactBalanceLine extends StatelessWidget {
  final double balance;

  const CompactBalanceLine({required this.balance, super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    final color = balance >= 0 ? finance.income : finance.expense;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp2),
      child: Row(
        children: [
          const Eyebrow('Reste à vivre'),
          const SizedBox(width: FrostedSpacing.sp3),
          Expanded(
            child: Text(
              NumberFormat.currency(
                locale: 'fr_FR',
                symbol: '€',
              ).format(balance),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.amount(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
