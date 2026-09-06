import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';

class QuickAddDemoPhrase {
  const QuickAddDemoPhrase({
    required this.text,
    required this.amount,
    required this.categorySlug,
    required this.dateLabel,
    this.type = TransactionType.expense,
    this.frequency = Frequency.oneTime,
  });
  final String text;
  final double amount;
  final String categorySlug;
  final String dateLabel;
  final TransactionType type;
  final Frequency frequency;
}

class RecurrenceDemo {
  const RecurrenceDemo({
    required this.phrase,
    required this.name,
    required this.amount,
    required this.categorySlug,
    required this.frequency,
    required this.reportedMonths,
  });
  final String phrase;
  final String name;
  final double amount;
  final String categorySlug;
  final Frequency frequency;
  final int reportedMonths;
}

class ReceiptDemoLine {
  const ReceiptDemoLine({
    required this.label,
    required this.amount,
    required this.categorySlug,
  });
  final String label;
  final double amount;
  final String categorySlug;
}

class ReceiptDemo {
  const ReceiptDemo({required this.store, required this.lines});
  final String store;
  final List<ReceiptDemoLine> lines;

  double get total => lines.fold<double>(0, (sum, line) => sum + line.amount);
}

abstract final class OnboardingDemo {
  static const String todayLabel = 'Aujourd\'hui';

  static const List<QuickAddDemoPhrase> phrases = [
    QuickAddDemoPhrase(
      text: 'courses carrefour 42',
      amount: 42,
      categorySlug: 'alimentation.courses',
      dateLabel: todayLabel,
    ),
    QuickAddDemoPhrase(
      text: 'plein d\'essence 68',
      amount: 68,
      categorySlug: 'transport.carburant',
      dateLabel: todayLabel,
    ),
    QuickAddDemoPhrase(
      text: 'pharmacie 12,40',
      amount: 12.40,
      categorySlug: 'sante_beaute.pharmacie',
      dateLabel: todayLabel,
    ),
  ];

  static const RecurrenceDemo recurrence = RecurrenceDemo(
    phrase: 'netflix 15,99 tous les mois',
    name: 'Netflix',
    amount: 15.99,
    categorySlug: 'loisirs.streaming',
    frequency: Frequency.monthly,
    reportedMonths: 3,
  );

  static const ReceiptDemo receipt = ReceiptDemo(
    store: 'CARREFOUR MARKET',
    lines: [
      ReceiptDemoLine(
        label: 'Pâtes 500g',
        amount: 2.15,
        categorySlug: 'alimentation.courses',
      ),
      ReceiptDemoLine(
        label: 'Baguette tradition',
        amount: 1.20,
        categorySlug: 'alimentation.pain_patisserie',
      ),
      ReceiptDemoLine(
        label: 'Dentifrice',
        amount: 3.45,
        categorySlug: 'sante_beaute.cosmetiques',
      ),
      ReceiptDemoLine(
        label: 'Piles LR6 x4',
        amount: 5.60,
        categorySlug: 'shopping.electronique',
      ),
    ],
  );

  static List<String> get quickAddSlugs => [
    ...phrases.map((phrase) => phrase.categorySlug),
    recurrence.categorySlug,
  ];

  static List<String> get receiptSlugs =>
      receipt.lines.map((line) => line.categorySlug).toList();

  static List<String> get slugs => [...quickAddSlugs, ...receiptSlugs];
}
