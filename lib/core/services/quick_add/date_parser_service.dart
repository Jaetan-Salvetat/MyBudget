/// Reads the date a free-text entry carries, so a transaction can be typed
/// long after it happened.
///
/// Runs before the price is read and hands back the text without its date :
/// left in place, "le 12" would be taken for an amount, and the model would
/// have to make sense of words it never saw during training.
/// The user notes what has been spent : every form but "demain" resolves to
/// the most recent matching day that has already come.
abstract final class DateParserService {
  static const int _daysInWeek = 7;

  static final RegExp _whitespace = RegExp(r'\s{2,}');

  static const Map<String, int> _weekdays = {
    'lundi': DateTime.monday,
    'mardi': DateTime.tuesday,
    'mercredi': DateTime.wednesday,
    'jeudi': DateTime.thursday,
    'vendredi': DateTime.friday,
    'samedi': DateTime.saturday,
    'dimanche': DateTime.sunday,
  };

  static const List<String> _monthPatterns = [
    'janvier',
    'f[ée]vrier',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'ao[uû]t',
    'septembre',
    'octobre',
    'novembre',
    'd[ée]cembre',
  ];

  static final RegExp _dayBefore = RegExp(
    r'\bavant[\s-]hier\b',
    caseSensitive: false,
  );
  static final RegExp _yesterday = RegExp(r'\bhier\b', caseSensitive: false);
  static final RegExp _today = RegExp(
    r"\baujourd[’']?\s?hui\b",
    caseSensitive: false,
  );
  static final RegExp _tomorrow = RegExp(r'\bdemain\b', caseSensitive: false);
  static final RegExp _ago = RegExp(
    r'\bil y a (\d{1,3}) (jours?|semaines?|mois)\b',
    caseSensitive: false,
  );
  static final RegExp _weekday = RegExp(
    '\\b(${_weekdays.keys.join('|')})(\\s+dernier)?\\b',
    caseSensitive: false,
  );
  static final RegExp _namedMonth = RegExp(
    '\\b(?:le\\s+)?(\\d{1,2})(?:er)?\\s+(${_monthPatterns.join('|')})'
    '(?:\\s+(\\d{4}))?\\b',
    caseSensitive: false,
  );
  static final RegExp _slashed = RegExp(
    r'\b(?:le\s+)?(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b',
    caseSensitive: false,
  );

  /// A bare number is an amount, never a date : only "le" turns it into one.
  static final RegExp _dayOfMonth = RegExp(
    r'\ble\s+(\d{1,2})\b',
    caseSensitive: false,
  );

  /// Null when the text carries no date, which is the common case.
  static DateParseResult? parse(String input, {DateTime? today}) {
    if (input.trim().isEmpty) return null;

    final reference = _atMidnight(today ?? DateTime.now());
    final match = _firstOf(input, reference);
    if (match == null) return null;

    return DateParseResult(
      date: match.date,
      remaining: _withoutSpan(input, match.start, match.end),
    );
  }

  /// The date the user wrote first wins. At equal position the longest match
  /// wins, so "le 12 mars" is not cut down to "le 12".
  static _DateMatch? _firstOf(String input, DateTime reference) {
    final matches = <_DateMatch>[
      ..._relative(input, reference),
      ..._weekdayMatches(input, reference),
      ..._explicit(input, reference),
    ];
    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      return (b.end - b.start).compareTo(a.end - a.start);
    });
    return matches.first;
  }

  static List<_DateMatch> _relative(String input, DateTime reference) {
    final matches = <_DateMatch>[];

    void add(RegExp pattern, DateTime Function(RegExpMatch match) resolve) {
      for (final match in pattern.allMatches(input)) {
        matches.add(
          _DateMatch(resolve(match), match.start, match.end),
        );
      }
    }

    add(_dayBefore, (_) => reference.subtract(const Duration(days: 2)));
    add(_yesterday, (_) => reference.subtract(const Duration(days: 1)));
    add(_today, (_) => reference);
    add(_tomorrow, (_) => reference.add(const Duration(days: 1)));
    add(_ago, (match) => _agoDate(reference, match));

    return matches;
  }

  static DateTime _agoDate(DateTime reference, RegExpMatch match) {
    final count = int.parse(match.group(1)!);
    final unit = match.group(2)!.toLowerCase();
    if (unit.startsWith('mois')) {
      return DateTime(reference.year, reference.month - count, reference.day);
    }
    final days = unit.startsWith('semaine') ? count * _daysInWeek : count;
    return reference.subtract(Duration(days: days));
  }

  /// "samedi" is the last Saturday that has come, today included. "dernier"
  /// steps back a full week from there, which only shows when the weekday
  /// written is today's.
  static List<_DateMatch> _weekdayMatches(String input, DateTime reference) {
    return [
      for (final match in _weekday.allMatches(input))
        _DateMatch(
          _lastWeekday(
            reference,
            _weekdays[match.group(1)!.toLowerCase()]!,
            steppedBack: match.group(2) != null,
          ),
          match.start,
          match.end,
        ),
    ];
  }

  static DateTime _lastWeekday(
    DateTime reference,
    int weekday, {
    required bool steppedBack,
  }) {
    var back = (reference.weekday - weekday) % _daysInWeek;
    if (steppedBack && back == 0) back = _daysInWeek;
    return reference.subtract(Duration(days: back));
  }

  static List<_DateMatch> _explicit(String input, DateTime reference) {
    final matches = <_DateMatch>[];

    for (final match in _slashed.allMatches(input)) {
      final date = _dated(
        reference,
        day: int.parse(match.group(1)!),
        month: int.parse(match.group(2)!),
        year: _yearOf(match.group(3)),
      );
      if (date != null) matches.add(_DateMatch(date, match.start, match.end));
    }

    for (final match in _namedMonth.allMatches(input)) {
      final date = _dated(
        reference,
        day: int.parse(match.group(1)!),
        month: _monthNumberOf(match.group(2)!),
        year: _yearOf(match.group(3)),
      );
      if (date != null) matches.add(_DateMatch(date, match.start, match.end));
    }

    for (final match in _dayOfMonth.allMatches(input)) {
      final date = _dated(reference, day: int.parse(match.group(1)!));
      if (date != null) matches.add(_DateMatch(date, match.start, match.end));
    }

    return matches;
  }

  static int? _yearOf(String? written) {
    if (written == null) return null;
    final value = int.parse(written);
    return written.length == 2 ? 2000 + value : value;
  }

  static int _monthNumberOf(String written) {
    final normalized = written.toLowerCase();
    return _monthPatterns.indexWhere(
          (pattern) => RegExp('^$pattern\$').hasMatch(normalized),
        ) +
        1;
  }

  /// Null when the numbers do not name a real day. Without an explicit year,
  /// a day still to come belongs to the period before : nobody records
  /// tomorrow's groceries by writing their date.
  static DateTime? _dated(
    DateTime reference, {
    required int day,
    int? month,
    int? year,
  }) {
    if (day < 1 || day > 31) return null;
    if (month != null && (month < 1 || month > 12)) return null;

    final resolved = DateTime(
      year ?? reference.year,
      month ?? reference.month,
      day,
    );
    if (resolved.day != day) return null;
    if (year != null || !resolved.isAfter(reference)) return resolved;

    return month == null
        ? DateTime(reference.year, reference.month - 1, day)
        : DateTime(reference.year - 1, month, day);
  }

  static DateTime _atMidnight(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  static String _withoutSpan(String input, int start, int end) {
    final joined = '${input.substring(0, start)} ${input.substring(end)}';
    return joined.replaceAll(_whitespace, ' ').trim();
  }
}

class DateParseResult {
  final DateTime date;
  final String remaining;

  const DateParseResult({required this.date, required this.remaining});
}

class _DateMatch {
  final DateTime date;
  final int start;
  final int end;

  const _DateMatch(this.date, this.start, this.end);
}
