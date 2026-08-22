import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';

enum AmountDirection { income, expense, neutral }

class AmountText extends StatelessWidget {
  final double amount;
  final AmountDirection direction;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showSign;
  final int decimals;
  final bool serifItalic;
  final Color? overrideColor;

  const AmountText({
    super.key,
    required this.amount,
    this.direction = AmountDirection.neutral,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w600,
    this.showSign = false,
    this.decimals = 2,
    this.serifItalic = false,
    this.overrideColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = overrideColor ?? _resolveColor(context);
    final formatted = _format();
    final style = serifItalic
        ? AppTextStyles.displaySerifItalic(fontSize: fontSize, color: color)
        : AppTextStyles.amount(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          );
    return Text(formatted, style: style);
  }

  Color _resolveColor(BuildContext context) {
    final finance = context.financeColors;
    switch (direction) {
      case AmountDirection.income:
        return finance.income;
      case AmountDirection.expense:
        return finance.expense;
      case AmountDirection.neutral:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  String _format() {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: decimals,
    );
    final formatted = formatter.format(amount.abs());
    if (!showSign) return formatted;
    final prefix = direction == AmountDirection.income
        ? '+ '
        : direction == AmountDirection.expense
        ? '− '
        : '';
    return '$prefix$formatted';
  }
}
