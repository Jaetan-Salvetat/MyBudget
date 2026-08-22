import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/dashboard/widgets/compact_balance_line.dart';
import 'package:mybudget/ui/dashboard/widgets/hero_balance_card.dart';

/// The month's balance, full card normally, one line while the user types :
/// the number has to stay readable above the keyboard.
///
/// Height only, never a cross-fade. Two reasons : the card is glass, and a
/// backdrop filter inside an opacity layer samples that layer instead of the
/// screen — it paints a grey block over the card for the whole transition ;
/// and both layouts carry the same figure, so overlapping them prints it twice.
class DashboardHeaderBalance extends StatelessWidget {
  static const Duration duration = Duration(milliseconds: 320);

  final bool typing;
  final double balance;
  final double totalIncomes;
  final double totalExpenses;

  const DashboardHeaderBalance({
    required this.typing,
    required this.balance,
    required this.totalIncomes,
    required this.totalExpenses,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: context.frostedTokens.motion.snappy.curve,
      alignment: Alignment.topCenter,
      child: typing
          ? CompactBalanceLine(balance: balance)
          : HeroBalanceCard(
              balance: balance,
              totalIncomes: totalIncomes,
              totalExpenses: totalExpenses,
            ),
    );
  }
}
