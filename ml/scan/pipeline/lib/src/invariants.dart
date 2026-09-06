library;

import 'line_features.dart';
import 'structure.dart';

enum EvidenceSource { classifier, tax, paymentChange, sections, totalLine }

const List<double> _taxRates = [0.021, 0.055, 0.10, 0.20];
const double _taxToleranceCents = 1.0;
const Set<String> _rateLiterals = {
  '20.00',
  '20,00',
  '10.00',
  '10,00',
  '5.50',
  '5,50',
  '2.10',
  '2,10',
};
const Set<String> _ratePercentages = {
  '20',
  '10',
  '5.5',
  '5,5',
  '2.1',
  '2,1',
  '20.00',
  '20,00',
  '10.00',
  '10,00',
};
const List<String> htWords = ['HT', 'H.T', 'NET', 'TTL', 'BASE'];
const List<String> changeWords = ['RENDU', 'RENDRE', 'MONNAIE', 'CHANGE'];
const int _minTableRowAmounts = 2;
const int _minRecapDiscounts = 2;
const int _minBareSectionLines = 2;
const int _minSectionsForEvidence = 2;

class Evidence {
  const Evidence({
    required this.cents,
    required this.cutoffRank,
    required this.source,
    required this.lineRank,
  });

  final int cents;
  final int cutoffRank;
  final EvidenceSource source;
  final int? lineRank;
}

class Constraints {
  const Constraints({
    required this.forcedIgnore,
    required this.referenceRanks,
    required this.evidences,
    this.softIgnore = const {},
  });

  final Set<int> forcedIgnore;
  final Set<int> referenceRanks;
  final List<Evidence> evidences;
  final Set<int> softIgnore;
}

int _cents(double price) => (price * 100).round();

bool _isRateToken(String token) {
  if (_rateLiterals.contains(token)) return true;
  return token.endsWith('%') &&
      _ratePercentages.contains(token.substring(0, token.length - 1));
}

bool _carriesItsOwnTaxSplit(List<int> amounts) {
  for (var index = 0; index < amounts.length; index++) {
    final ttc = amounts[index];
    final rest = [...amounts.sublist(0, index), ...amounts.sublist(index + 1)];
    for (var position = 0; position < rest.length; position++) {
      final ht = rest[position];
      for (final tax in rest.sublist(position + 1)) {
        if (ht + tax != ttc) continue;
        if (_taxMatches(ht, tax) || _taxMatches(tax, ht)) return true;
      }
    }
  }
  return false;
}

bool _isTaxRow(PricedLine priced) {
  if (containsEntry(priced.line.text, tvaWords)) return true;
  final amounts = _rowAmounts(priced);
  if (_carriesItsOwnTaxSplit(amounts)) return true;
  final hasRate = priced.line.words.any((word) => _isRateToken(word.text));
  return hasRate && amounts.length >= _minTableRowAmounts;
}

List<int> _rowAmounts(PricedLine priced) {
  final amounts = <int>[];
  for (final word in priced.line.words) {
    if (_isRateToken(word.text)) continue;
    final price = parsePrice(word.text);
    if (price != null && price != 0) amounts.add(_cents(price).abs());
  }
  return amounts;
}

bool _taxMatches(int htCents, int taxCents) => _taxRates.any(
  (rate) => (taxCents - htCents * rate).abs() <= _taxToleranceCents,
);

bool _isExcludedTotal(String text) =>
    containsEntry(text, excludedTotalWords) &&
    !containsEntry(text, taxInclusiveWords);

bool _isHtLine(PricedLine priced) {
  final text = priced.line.text;
  if (!containsEntry(text, htWords)) return false;
  return !containsTotal(text) || _isExcludedTotal(text);
}

class _TaxPair {
  const _TaxPair(this.ht, this.tax, this.partnerRank, this.printed);

  final int ht;
  final int tax;
  final int? partnerRank;
  final bool printed;
}

List<int> _sortedAmounts(List<int> amounts) => [...amounts]..sort();

List<int> _partnersByDistance(Map<int, List<int>> partners, int rank) {
  final ranks = partners.keys.toList();
  final indexed = [for (final (i, r) in ranks.indexed) (i, r)];
  indexed.sort((a, b) {
    final byDistance = (a.$2 - rank).abs().compareTo((b.$2 - rank).abs());
    return byDistance != 0 ? byDistance : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

List<_TaxPair> _rowPairs(
  int rank,
  List<int> amounts,
  Map<int, List<int>> partners,
  Set<int> used,
) {
  final pairs = <_TaxPair>[];
  for (final tax in _sortedAmounts(amounts)) {
    for (final ht in amounts) {
      if (ht > tax && _taxMatches(ht, tax)) {
        pairs.add(_TaxPair(ht, tax, null, amounts.contains(ht + tax)));
      }
    }
  }
  for (final tax in _sortedAmounts(amounts)) {
    for (final partnerRank in _partnersByDistance(partners, rank)) {
      if (partnerRank == rank || used.contains(partnerRank)) continue;
      for (final ht in partners[partnerRank]!) {
        if (ht > tax && _taxMatches(ht, tax)) {
          pairs.add(_TaxPair(ht, tax, partnerRank, amounts.contains(ht + tax)));
        }
      }
    }
  }
  return pairs;
}

(int, int, int) _pairKey(_TaxPair pair, int rank) => (
  pair.printed ? 0 : 1,
  pair.partnerRank == null ? 0 : 1,
  ((pair.partnerRank ?? rank) - rank).abs(),
);

int _compareKeys((int, int, int) a, (int, int, int) b) {
  final first = a.$1.compareTo(b.$1);
  if (first != 0) return first;
  final second = a.$2.compareTo(b.$2);
  if (second != 0) return second;
  return a.$3.compareTo(b.$3);
}

_TaxPair? _bestPair(List<_TaxPair> pairs, int rank) {
  _TaxPair? best;
  (int, int, int)? bestKey;
  for (final pair in pairs) {
    final key = _pairKey(pair, rank);
    if (best == null || _compareKeys(key, bestKey!) < 0) {
      best = pair;
      bestKey = key;
    }
  }
  return best;
}

(Evidence?, Set<int>) taxEvidence(List<PricedLine> lines) {
  final taxRows = <int>{
    for (final (rank, priced) in lines.indexed)
      if (_isTaxRow(priced)) rank,
  };
  final partners = <int, List<int>>{};
  for (final (rank, priced) in lines.indexed) {
    if (taxRows.contains(rank)) {
      partners[rank] = _rowAmounts(priced);
    } else if (_isHtLine(priced) && priced.price > 0) {
      partners[rank] = [_cents(priced.price)];
    }
  }
  final used = <int>{};
  var ttcTotal = 0;
  for (final rank in taxRows.toList()..sort()) {
    if (used.contains(rank)) continue;
    final pair = _bestPair(
      _rowPairs(rank, _rowAmounts(lines[rank]), partners, used),
      rank,
    );
    if (pair == null) continue;
    ttcTotal += pair.ht + pair.tax;
    used.add(rank);
    if (pair.partnerRank case final partnerRank?) used.add(partnerRank);
  }
  if (used.isEmpty) return (null, <int>{});
  final cutoff = used.reduce((a, b) => a < b ? a : b);
  return (
    Evidence(
      cents: ttcTotal,
      cutoffRank: cutoff,
      source: EvidenceSource.tax,
      lineRank: null,
    ),
    used,
  );
}

bool _isChangeLine(PricedLine priced) =>
    containsEntry(priced.line.text, changeWords);

Evidence? paymentChangeEvidence(List<PricedLine> lines) {
  int? changeRank;
  for (final (rank, priced) in lines.indexed) {
    if (_isChangeLine(priced) && _cents(priced.price) != 0) {
      changeRank = rank;
      break;
    }
  }
  if (changeRank == null) return null;
  (int, int)? given;
  for (var rank = 0; rank < changeRank; rank++) {
    final priced = lines[rank];
    if (!containsEntry(priced.line.text, paymentWords) ||
        _isChangeLine(priced) ||
        priced.price <= 0) {
      continue;
    }
    final candidate = (_cents(priced.price), rank);
    if (given == null ||
        candidate.$1 > given.$1 ||
        (candidate.$1 == given.$1 && candidate.$2 > given.$2)) {
      given = candidate;
    }
  }
  if (given == null) return null;
  final settled = given.$1 - _cents(lines[changeRank].price).abs();
  if (settled <= 0) return null;
  return Evidence(
    cents: settled,
    cutoffRank: given.$2,
    source: EvidenceSource.paymentChange,
    lineRank: null,
  );
}

bool _isSubtotal(PricedLine priced) =>
    containsEntry(priced.line.text, subtotalWords);

bool _isFinalTotalCandidate(PricedLine priced) {
  final text = priced.line.text;
  return containsTotal(text) && !_isSubtotal(priced) && !_isExcludedTotal(text);
}

int? _firstPaymentRank(List<PricedLine> lines) {
  for (final (rank, priced) in lines.indexed) {
    if (containsEntry(priced.line.text, paymentWords) &&
        !_isChangeLine(priced)) {
      return rank;
    }
  }
  return null;
}

Set<int> discountRecapRanks(List<PricedLine> lines) {
  final recaps = <int>{};
  final discounts = <int>[];
  for (final (rank, priced) in lines.indexed) {
    final cents = _cents(priced.price);
    if (cents == 0) continue;
    final sum = discounts.fold(0, (total, c) => total + c.abs());
    if (discounts.length >= _minRecapDiscounts && cents.abs() == sum) {
      recaps.add(rank);
      continue;
    }
    if (cents < 0) discounts.add(cents);
  }
  return recaps;
}

int? lastTotalRank(List<PricedLine> lines) {
  final recaps = discountRecapRanks(lines);
  final ranks = [
    for (final (rank, priced) in lines.indexed)
      if (_isFinalTotalCandidate(priced) &&
          !recaps.contains(rank) &&
          !_carriesItsOwnTaxSplit(_rowAmounts(priced)))
        rank,
  ];
  if (ranks.isEmpty) return null;
  final payment = _firstPaymentRank(lines);
  final beforePayment = [
    for (final rank in ranks)
      if (payment == null || rank < payment) rank,
  ];
  return beforePayment.isNotEmpty ? beforePayment.last : ranks.last;
}

Set<int> summaryDiscountRanks(List<PricedLine> lines) {
  final lastTotal = lastTotalRank(lines);
  final scope = lastTotal ?? lines.length;
  final real = <int>[];
  final summaries = <int>{};
  for (var rank = 0; rank < scope; rank++) {
    final priced = lines[rank];
    final cents = _cents(priced.price);
    final text = priced.line.text;
    if (cents >= 0 && !containsEntry(text, discountWords)) continue;
    final isTotalLine = containsTotal(text);
    final realSum = real.fold(0, (sum, value) => sum + value.abs());
    final recap = real.isNotEmpty && cents.abs() == realSum;
    if (recap && (real.length >= 2 || isTotalLine)) {
      summaries.add(rank);
      continue;
    }
    if (!isTotalLine) real.add(cents);
  }
  return summaries;
}

int _sectionScope(List<PricedLine> lines) {
  final lastTotal = lastTotalRank(lines);
  return lastTotal == null ? lines.length : lastTotal + 1;
}

bool _discountFollows(List<PricedLine> lines, int rank) {
  final scope = _sectionScope(lines);
  for (var other = rank + 1; other < scope; other++) {
    final priced = lines[other];
    if (_cents(priced.price) < 0 ||
        containsEntry(priced.line.text, discountWords)) {
      return true;
    }
  }
  return false;
}

bool _isLexical(PricedLine priced) {
  final text = priced.line.text;
  return containsTotal(text) ||
      _isSubtotal(priced) ||
      containsEntry(text, paymentWords) ||
      containsEntry(text, tvaWords) ||
      containsEntry(text, discountWords) ||
      _isChangeLine(priced);
}

bool _isItemCandidate(PricedLine priced, Set<int> excluded, int rank) =>
    priced.price > 0 && !excluded.contains(rank) && !_isLexical(priced);

bool _itemsFollow(List<PricedLine> lines, int rank) {
  final scope = _sectionScope(lines);
  for (var other = rank + 1; other < scope; other++) {
    if (_isItemCandidate(lines[other], const {}, other)) return true;
  }
  return false;
}

bool _closesTheItems(List<PricedLine> lines, int rank) =>
    !_itemsFollow(lines, rank) && !_discountFollows(lines, rank);

bool _isIntermediateReference(
  List<PricedLine> lines,
  int rank,
  List<int> sections,
) {
  final priced = lines[rank];
  if (!(containsTotal(priced.line.text) || _isSubtotal(priced))) return false;
  final cents = _cents(priced.price);
  final blocked = sections.any(
    (section) => section < rank && _cents(lines[section].price) != cents,
  );
  if (blocked) return false;
  return _closesTheItems(lines, rank);
}

bool _isEligibleReference(
  List<PricedLine> lines,
  int rank,
  int? lastTotal,
  List<int> sections,
) {
  final priced = lines[rank];
  if (lastTotal == null) {
    return !(_isSubtotal(priced) && _discountFollows(lines, rank));
  }
  if (rank >= lastTotal) return !_isSubtotal(priced);
  return _isIntermediateReference(lines, rank, sections);
}

Set<int> referenceRanks(List<PricedLine> lines) {
  final lastTotal = lastTotalRank(lines);
  final sections = sectionTotals(lines);
  return {
    for (final (rank, priced) in lines.indexed)
      if (!_isExcludedTotal(priced.line.text) &&
          _isEligibleReference(lines, rank, lastTotal, sections))
        rank,
  };
}

List<int> sectionTotals(List<PricedLine> lines, [Set<int>? excluded]) {
  final skipped = excluded ?? const <int>{};
  final sections = <int>[];
  var running = 0;
  var count = 0;
  final lastTotal = lastTotalRank(lines);
  final scope = _sectionScope(lines);
  for (var rank = 0; rank < scope; rank++) {
    final priced = lines[rank];
    final cents = _cents(priced.price);
    if (skipped.contains(rank) || cents <= 0) continue;
    final minimum = containsTotal(priced.line.text) ? 1 : _minBareSectionLines;
    final closesLastTotal = rank == lastTotal && sections.isEmpty;
    if (count >= minimum && cents == running && !closesLastTotal) {
      sections.add(rank);
      running = 0;
      count = 0;
      continue;
    }
    if (_isItemCandidate(priced, skipped, rank)) {
      running += cents;
      count += 1;
    }
  }
  return sections;
}

bool _sectionsCoverItems(
  List<PricedLine> lines,
  List<int> sections,
  Set<int> excluded,
) {
  final lastTotal = lastTotalRank(lines);
  final scope = lastTotal ?? lines.length;
  for (var rank = sections.last + 1; rank < scope; rank++) {
    if (_isItemCandidate(lines[rank], excluded, rank)) return false;
  }
  return true;
}

Evidence? _sectionsEvidence(
  List<PricedLine> lines,
  List<int> sections,
  Set<int> excluded,
) {
  if (sections.length < _minSectionsForEvidence) return null;
  if (!_sectionsCoverItems(lines, sections, excluded)) return null;
  final total = sections.fold(
    0,
    (sum, rank) => sum + _cents(lines[rank].price),
  );
  return Evidence(
    cents: total,
    cutoffRank: sections.last,
    source: EvidenceSource.sections,
    lineRank: null,
  );
}

Constraints constraints(List<PricedLine> lines) {
  final (tax, taxIgnored) = taxEvidence(lines);
  final summaries = summaryDiscountRanks(lines);
  final forced = <int>{
    ...taxIgnored,
    ...summaries,
    ...discountRecapRanks(lines),
  };
  final sections = sectionTotals(lines, forced);
  final evidences = <Evidence>[];
  if (tax != null) evidences.add(tax);
  final settled = paymentChangeEvidence(lines);
  if (settled != null) evidences.add(settled);
  final bySections = _sectionsEvidence(lines, sections, forced);
  if (bySections != null) evidences.add(bySections);
  final lastTotal = lastTotalRank(lines);
  if (lastTotal != null && lines[lastTotal].price > 0) {
    evidences.add(
      Evidence(
        cents: _cents(lines[lastTotal].price),
        cutoffRank: lastTotal,
        source: EvidenceSource.totalLine,
        lineRank: lastTotal,
      ),
    );
  }
  return Constraints(
    forcedIgnore: forced,
    referenceRanks: referenceRanks(lines).difference(forced),
    evidences: evidences,
    softIgnore: sections.toSet(),
  );
}
