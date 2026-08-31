import 'package:mybudget/core/entities/transaction_rule_summary.dart';
import 'package:mybudget/core/entities/transaction_rule_version.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/utils/history_utils.dart';

const int _monthsInYear = 12;

class TransactionRuleSummaryService {
  const TransactionRuleSummaryService._();

  static TransactionRuleSummary summarize(
    List<TransactionRuleVersion> versions, {
    required DateTime asOf,
  }) {
    if (versions.isEmpty) {
      throw ArgumentError.value(versions, 'versions', 'Aucune version fournie');
    }

    final ordered = [...versions]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final current = ordered.lastWhere(
      (version) => version.isOpen,
      orElse: () => ordered.last,
    );

    var occurrences = 0;
    var totalToDate = 0.0;
    for (final version in ordered) {
      final landings = _occurrencesOf(version, asOf);
      occurrences += landings;
      totalToDate += landings * version.amount;
    }

    return TransactionRuleSummary(
      occurrences: occurrences,
      totalToDate: totalToDate,
      since: ordered.first.startDate,
      nextDueDate: _nextDueDateOf(current, asOf),
      annualImpact: _annualImpactOf(current),
    );
  }

  static int _occurrencesOf(TransactionRuleVersion version, DateTime asOf) {
    final closing = version.endDate;
    final limit = closing == null || dayOnly(asOf).isBefore(dayOnly(closing))
        ? dayOnly(asOf)
        : dayOnly(closing);
    if (limit.isBefore(dayOnly(version.startDate))) return 0;

    var count = 0;
    var month = DateTime(version.startDate.year, version.startDate.month);
    final lastMonth = DateTime(limit.year, limit.month);
    while (!month.isAfter(lastMonth)) {
      if (_landsIn(version, month) &&
          !_landingIn(version, month).isAfter(limit)) {
        count++;
      }
      month = DateTime(month.year, month.month + 1);
    }
    return count;
  }

  static DateTime? _nextDueDateOf(
    TransactionRuleVersion version,
    DateTime asOf,
  ) {
    final from = dayOnly(asOf);

    if (version.frequency == Frequency.oneTime) {
      final landing = dayOnly(version.startDate);
      return landing.isBefore(from) ? null : landing;
    }

    final start = dayOnly(version.startDate);
    final scanFrom = start.isAfter(from) ? start : from;
    var month = DateTime(scanFrom.year, scanFrom.month);
    for (var scanned = 0; scanned <= _monthsInYear; scanned++) {
      if (_landsIn(version, month)) {
        final landing = _landingIn(version, month);
        if (!landing.isBefore(scanFrom)) return landing;
      }
      month = DateTime(month.year, month.month + 1);
    }
    return null;
  }

  static double? _annualImpactOf(TransactionRuleVersion version) {
    return switch (version.frequency) {
      Frequency.monthly => version.amount * _monthsInYear,
      Frequency.annual => version.amount,
      Frequency.oneTime => null,
    };
  }

  static bool _landsIn(TransactionRuleVersion version, DateTime month) {
    return occursInMonth(
      version.startDate,
      version.endDate,
      version.frequency,
      month,
    );
  }

  static DateTime _landingIn(TransactionRuleVersion version, DateTime month) {
    return dayOnly(dayInMonthOf(version.startDate, version.frequency, month));
  }
}
