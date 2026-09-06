import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';

class EffortRateSection extends StatelessWidget {
  static const double barThickness = 9;

  final double? rate;
  final double? annualRate;
  final double recurringExpenses;
  final double leftover;

  const EffortRateSection({
    super.key,
    required this.rate,
    required this.annualRate,
    required this.recurringExpenses,
    required this.leftover,
  });

  @override
  Widget build(BuildContext context) {
    final rate = this.rate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Part incompressible'),
        SolidCard(
          padding: const EdgeInsets.fromLTRB(15, 16, 15, 15),
          child: rate == null ? _MissingIncome() : _rated(context, rate),
        ),
      ],
    );
  }

  Widget _rated(BuildContext context, double rate) {
    final finance = context.financeColors;
    final scheme = Theme.of(context).colorScheme;
    final reference = _referenceLabel(rate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _percent(rate),
              style: AppTextStyles.displaySerifItalic(
                fontSize: 38,
                height: 1,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'de tes revenus sont déjà engagés ce mois-ci',
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        FrostedStackedBar(
          segments: _segments(finance.expense, finance.income),
          thickness: barThickness,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fixe ${_money(recurringExpenses)}',
              style: _footnote(scheme.onSurfaceVariant),
            ),
            Text(
              'Reste à vivre ${_money(leftover)}',
              style: _footnote(scheme.onSurfaceVariant),
            ),
          ],
        ),
        if (reference != null) ...[
          const SizedBox(height: 11),
          Text(reference, style: _footnote(scheme.onSurfaceVariant)),
        ],
      ],
    );
  }

  String? _referenceLabel(double rate) {
    final annualRate = this.annualRate;
    if (annualRate == null) return null;
    if (_percent(annualRate) == _percent(rate)) return null;
    return '${_percent(annualRate)} sur 12 mois, charges annuelles comprises';
  }

  List<FrostedBarSegment> _segments(Color charges, Color rest) {
    if (leftover <= 0) {
      return [FrostedBarSegment(value: 1, color: charges)];
    }

    return [
      FrostedBarSegment(value: recurringExpenses, color: charges),
      FrostedBarSegment(value: leftover, color: rest),
    ];
  }

  TextStyle _footnote(Color color) => AppTextStyles.mono(
    fontSize: 9.5,
    lineHeight: 13,
    letterSpacingEm: 0.03,
    color: color,
  );

  String _percent(double rate) => '${(rate * 100).round()} %';

  String _money(double amount) => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  ).format(amount);
}

class _MissingIncome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      'Ajoute tes revenus récurrents pour voir la part déjà engagée chaque mois.',
      style: AppTextStyles.mono(
        fontSize: 10.5,
        lineHeight: 15,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
