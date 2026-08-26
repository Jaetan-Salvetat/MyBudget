/// Structure les lignes physiques d'un ticket en articles + prix + remises.
///
/// Règles géométriques et lexicales pures, sans modèle. Portage de référence
/// de `ml/scan/research/reference/structure.py` : toute divergence de comportement
/// avec la version Python est un bug.
library;

import 'dart:math' as math;

import 'accent_fold.dart';
import 'lines.dart';

final RegExp _pricePattern = RegExp(r'^-?\d{1,4}[.,]\d{2}$');
final RegExp quantityPattern = RegExp(r'^(\d{1,2})[xX*](-?\d{1,4}[.,]\d{2})$');
final RegExp weightPattern = RegExp(
  r'^\d{1,3}[.,]\d{1,3}\s?[Kk]?[Gg][xX*]\d{1,4}[.,]\d{1,2}.*$',
);
final RegExp _missingSeparatorTotalPattern = RegExp(r'(\d{3,6})\s*$');
final RegExp _articleCountPattern = RegExp(r'(\d{1,3})ARTICLE');
/// Un numéro de téléphone français, retiré du texte avant toute recherche de
/// date. Sans ce masque, « 05.46.27.02.12 » se lit « 27.02.12 » : mesuré, 170
/// tickets de plus repartaient avec une fausse date.
///
/// Le séparateur doit être présent et le *même* entre les cinq paires. Sans
/// l'exiger identique, « 08-03-2017 12:42 » compacté ressemblait à un numéro ;
/// sans l'exiger présent, le masque avalait les codes de caisse — un ticket
/// est plein de suites de dix chiffres commençant par zéro, et « 0002 G04
/// 000643 22/02/2017 » y perdait sa date. Un numéro imprimé sans séparateur
/// ne se confond avec aucune date, il n'a pas besoin d'être masqué.
final RegExp _phonePattern = RegExp(r'(?<!\d)0\d([.\-])\d{2}(?:\1\d{2}){3}(?!\d)');

/// Une date de ticket, année sur quatre chiffres ou sur deux. L'année courte
/// exige une frontière à droite, sinon elle mord sur l'heure que le
/// compactage des espaces a recollée (« 13/03/17 20:30 » → « 13/03/1720:30 »).
/// Jour et mois peuvent n'avoir qu'un chiffre (« 7/10/15 », « 14/1/17 ») : le
/// masque des numéros et la validation calendaire tiennent les faux positifs.
final RegExp _datePattern = RegExp(
  r'(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}|\d{2}(?![\d./-]))',
);

/// Mois en toutes lettres ou abrégé : un ticket sur six l'imprime ainsi.
const List<String> _monthNames = [
  'JANV|JAN',
  'FEVR|FEV',
  'MARS|MAR',
  'AVRIL|AVR',
  'MAI',
  'JUIN|JUN',
  'JUILLET|JUIL|JUL',
  'AOUT|AOU',
  'SEPTEMBRE|SEPT|SEP',
  'OCTOBRE|OCT',
  'NOVEMBRE|NOV',
  'DECEMBRE|DEC',
];

final RegExp _literalDatePattern = RegExp(
  r'(\d{1,2})(?:ER)?[/.\- ]?(' +
      _monthNames.join('|') +
      r')[A-Z]*[/.\- ]?(\d{4}|\d{2})',
  caseSensitive: false,
);

/// Bornes d'une date de ticket : au-delà, l'année lue n'en est pas une.
const int _minYear = 1990;
const int _maxYear = 2035;

/// Pivot POSIX pour les années sur deux chiffres. Un ticket de caisse est
/// toujours du siècle courant, mais le pivot coûte moins qu'une hypothèse.
const int _centuryPivot = 70;
const int _maxDay = 31;
const int _maxMonth = 12;
final RegExp _integerPattern = RegExp(r'^-?\d{1,4}$');
final RegExp _decimalsPattern = RegExp(r'^[.,]?\d{2}$');
final RegExp _leaderDotsPattern = RegExp(r'^[.…]+');

const List<String> discountWords = [
  'REMISE',
  'PROMO',
  'DISCOUNT',
];

const List<String> totalWords = [
  'TOTAL',
  'TOT',
  'PAYER',
  'MONTANT DU',
  'NET A REGLER',
  'A REGLER',
  'DOIT',
  'PRIX TTC',
  'MONTANT TTC',
];

const String fuzzyTotalWord = 'TOTAL';
const int fuzzyTotalMaxDistance = 1;
const int fuzzyTotalMinTokenLength = 4;
const int fuzzyTotalMaxTokenLength = 6;

const List<String> subtotalWords = [
  'SOUS-TOTAL',
  'SOUS TOTAL',
  'SUBTOTAL',
  'SUB-TOTAL',
  'S/TOTAL',
  'S/TOT',
  'AMOUNT',
  'TAXABLE',
];

const List<String> stopWords = [
  'TOTAL',
  'PAYER',
  'SOUS-TOTAL',
  'TVA',
  'TUA',
  'CB ',
  'CARTE BANCAIRE',
  'ESPECES',
  'RENDU',
  'A RENDRE',
  'MONNAIE',
  'CHEQUE',
  'ARTICLE(',
  'ARTICLES',
  'MERCI',
  'TEL',
  'CAISSE',
  'TTC',
  'EMV',
  'SANS CONTACT',
  'VISITE',
  'INCL',
  'TAX',
  'VISA',
  'MASTERCARD',
  'CREDIT',
  'SERVER',
  'WELCOME',
  'FIDELITE',
  'CARTE BLEUE',
  'TOTAUX',
  'SOLDE',
  'PAIEMENT',
  'REGLEMENT',
  'PERCU',
  'RECU',
];

const List<String> excludedTotalWords = [
  'HT',
  'TVA',
  'TUA',
  'ELIGIBLE',
  'FRANC',
  'FRF',
];

const List<String> paymentWords = [
  'CB',
  'CARTE BANCAIRE',
  'CARTES BANCAIRES',
  'CARTE BLEUE',
  'VISA',
  'MASTERCARD',
  'SANS CONTACT',
  'EMV',
  'ESPECES',
  'CHEQUE',
  'PAIEMENT',
  'REGLEMENT',
  'MONTANT PERCU',
  'PERCU',
  'RECU',
];
const List<String> tvaWords = ['TVA', 'TUA', 'TAX'];
const List<String> taxInclusiveWords = ['INCL'];

class ExtractedItem {
  ExtractedItem({
    required this.name,
    required this.amount,
    required this.discount,
    this.lineIndex,
  });

  String name;
  final double amount;
  double discount;

  /// Ligne dont l'article vient. Sans elle, impossible de confronter un
  /// libellé à ce que le tagger de rôles dit de son voisinage — et la
  /// majorité des tickets aux articles faux ont les bons montants, seul le
  /// libellé est allé chercher la mauvaise ligne.
  final int? lineIndex;
}

class ExtractedReceipt {
  const ExtractedReceipt({
    required this.store,
    required this.date,
    required this.total,
    required this.subtotal,
    required this.payment,
    required this.items,
    this.tvaTtcSum,
    this.printedCount,
    this.fallbackReferences = const [],
  });

  final String? store;
  final String? date;
  final double? total;
  final double? subtotal;
  final double? payment;
  final List<ExtractedItem> items;
  final double? tvaTtcSum;
  final int? printedCount;
  final List<double> fallbackReferences;

  double get itemsSum => roundCents(
    items.fold(0.0, (sum, item) => sum + item.amount - item.discount),
  );

  /// La somme des articles doit retomber sur un montant imprimé : le total
  /// TTC en Europe, ou le sous-total hors taxe aux États-Unis. Le montant
  /// débité par carte ne sert de référence que si aucun total n'a été lu :
  /// quand un total lu ne colle pas, on flague — accepter sur la seule ligne
  /// de paiement laisserait passer des extractions fausses. Deux références
  /// de secours mesurées sur corpus : la somme des TTC de la table TVA
  /// (décomposition imprimée du total), et la ligne CB quand le compteur
  /// « N ARTICLE(S) » confirme qu'aucun article ne manque.
  bool get checksumOk {
    if (_matches(total) || _matches(subtotal)) return true;
    if (total == null && _matches(tvaTtcSum)) return true;
    if (total == null && fallbackReferences.any(_matches)) return true;
    if (_matches(payment)) {
      if (total == null) return true;
      if (printedCount == items.length) return true;
    }
    return false;
  }

  /// Le montant qui a réellement vérifié la somme des articles — c'est lui
  /// qu'on affiche, jamais un total lu qui ne colle pas.
  double? get verifiedTotal {
    if (_matches(total)) return total;
    if (_matches(subtotal)) return subtotal;
    if (total == null && _matches(tvaTtcSum)) return tvaTtcSum;
    if (total == null) {
      for (final candidate in fallbackReferences) {
        if (_matches(candidate)) return candidate;
      }
    }
    if (checksumOk && _matches(payment)) return payment;
    return null;
  }

  bool _matches(double? reference) =>
      reference != null && (itemsSum - reference).abs() < 0.005;
}

double roundCents(double value) => (value * 100).round() / 100;

final RegExp _glyphPricePattern = RegExp(r'^-?[\dIlOoS]{1,4}[.,][\dIlOoS]{2}$');
const Map<String, String> _glyphTranslation = {
  'I': '1',
  'l': '1',
  'O': '0',
  'o': '0',
  'S': '5',
};

final RegExp _trailingLetterPattern = RegExp(r'([.,]\d{2})[A-Za-z]$');
const String _damagedSeparator = ';';
const String _leadingPunctuation = ':';

double? parsePrice(String text) {
  final normalized = _stripLeading(
    text.replaceAll(_damagedSeparator, ','),
    _leadingPunctuation,
  );
  var cleaned = _stripEdges(
    normalized.replaceAll('€', '').replaceAll(r'$', ''),
    'eE',
  );
  cleaned = cleaned.replaceFirst(_leaderDotsPattern, '');
  cleaned = cleaned.replaceFirstMapped(
    _trailingLetterPattern,
    (match) => match.group(1)!,
  );
  if (!_pricePattern.hasMatch(cleaned)) {
    final deglyphed = _deglyphed(cleaned);
    if (deglyphed == null) return null;
    cleaned = deglyphed;
  }
  return double.tryParse(cleaned.replaceAll(',', '.'));
}

String _stripLeading(String text, String chars) {
  var start = 0;
  while (start < text.length && chars.contains(text[start])) {
    start++;
  }
  return text.substring(start);
}

String _stripEdges(String text, String chars) {
  var start = 0;
  var end = text.length;
  while (start < end && chars.contains(text[start])) {
    start++;
  }
  while (end > start && chars.contains(text[end - 1])) {
    end--;
  }
  return text.substring(start, end);
}

/// Prix dont l'OCR a confondu un chiffre avec une lettre (« 2.I8 »).
/// Substitution seulement quand la forme est clairement un prix et que les
/// chiffres restent majoritaires : le checksum valide derrière.
String? _deglyphed(String text) {
  if (!_glyphPricePattern.hasMatch(text)) return null;
  final digits = _countDigits(text);
  final letters = _countLetters(text);
  if (letters == 0 || digits < 2 * letters) return null;
  final candidate = text.split('').map((char) {
    return _glyphTranslation[char] ?? char;
  }).join();
  return _pricePattern.hasMatch(candidate) ? candidate : null;
}

final RegExp _letterPattern = RegExp(r'\p{L}', unicode: true);
final RegExp _digitPattern = RegExp(r'[0-9]');

int _countDigits(String text) => _digitPattern.allMatches(text).length;

int _countLetters(String text) => _letterPattern.allMatches(text).length;

final RegExp _fragmentHeadPattern = RegExp(r'^-?\d{1,4}[.,]$');
final RegExp _fragmentTailPattern = RegExp(r'^\d{2}[€eE]?$');

/// Refusionne un prix que l'OCR a coupé au séparateur décimal (« -1, 00 »,
/// « 5. 16 ») quand les deux morceaux se touchent presque.
PhysicalLine mergePriceFragments(PhysicalLine line) {
  final words = line.words;
  final merged = <Word>[];
  var index = 0;
  while (index < words.length) {
    final word = words[index];
    if (index + 1 < words.length) {
      final tail = words[index + 1];
      final gap = tail.left - word.right;
      final closeEnough = gap < (word.bottom - word.top) * 1.2;
      if (_fragmentHeadPattern.hasMatch(word.text) &&
          _fragmentTailPattern.hasMatch(tail.text) &&
          closeEnough) {
        merged.add(
          Word(
            text: word.text + tail.text,
            left: word.left,
            top: word.top < tail.top ? word.top : tail.top,
            right: tail.right,
            bottom: word.bottom > tail.bottom ? word.bottom : tail.bottom,
            confidence: _minConfidence(word, tail),
          ),
        );
        index += 2;
        continue;
      }
    }
    merged.add(word);
    index += 1;
  }
  return PhysicalLine(words: merged);
}

double? _minConfidence(Word first, Word second) {
  final scores = [
    for (final word in [first, second])
      if (word.confidence != null) word.confidence!,
  ];
  if (scores.isEmpty) return null;
  return scores.reduce((a, b) => a < b ? a : b);
}

final RegExp _gluedPricePattern = RegExp(
  r'^[A-Za-z]{1,5}(-?\d{1,4}[.,]\d{2})[€eE]?$',
);

class PricedWord {
  const PricedWord(this.price, this.word);

  final double price;
  final Word word;
}

PricedWord? rightmostPrice(PhysicalLine line) {
  for (final word in line.words.reversed) {
    final price = parsePrice(word.text);
    if (price != null) return PricedWord(price, word);
  }
  for (final word in line.words.reversed) {
    final glued = _gluedPricePattern.firstMatch(word.text);
    if (glued != null) {
      return PricedWord(
        double.parse(glued.group(1)!.replaceAll(',', '.')),
        word,
      );
    }
  }
  if (containsTotal(line.text)) {
    return _trailingJunkPrice(line) ?? _splitPrice(line);
  }
  return null;
}

final RegExp _trailingJunkPricePattern = RegExp(r'^(-?\d{1,4}[.,]\d{2})\S$');

/// Prix d'une ligne total suivi d'un caractère parasite (« 7.074 »,
/// « 3.10D ») : seul le contexte total autorise cette lecture, le checksum
/// valide derrière.
PricedWord? _trailingJunkPrice(PhysicalLine line) {
  for (final word in line.words.reversed) {
    final junk = _trailingJunkPricePattern.firstMatch(word.text);
    if (junk != null) {
      return PricedWord(
        double.parse(junk.group(1)!.replaceAll(',', '.')),
        word,
      );
    }
  }
  return null;
}

/// Récupère un prix dont le séparateur décimal n'a pas été lu : les gros
/// totaux en gras sortent parfois « 54 50 » en deux mots adjacents.
PricedWord? _splitPrice(PhysicalLine line) {
  final words = line.words;
  if (words.length < 2) return null;
  final units = words[words.length - 2];
  final decimals = words[words.length - 1];
  if (!_integerPattern.hasMatch(units.text) ||
      !_decimalsPattern.hasMatch(decimals.text)) {
    return null;
  }
  final gap = decimals.left - units.right;
  if (gap > (units.bottom - units.top) * 1.5) return null;
  final value = double.parse(
    '${units.text}.${_stripLeading(decimals.text, '.,')}',
  );
  return PricedWord(value, decimals);
}

String _labelOf(PhysicalLine line, Word priceWord) {
  return line.words
      .where((word) => !identical(word, priceWord))
      .map((word) => word.text)
      .join(' ');
}

/// Équivalent du NFD + suppression des diacritiques de la référence Python :
/// couvre le latin de base et le latin étendu-A précomposés — l'OCR sort
/// n'importe quel diacritique sur un ticket dégradé (« TŤC », « Š »).

String foldAccents(String text) {
  final buffer = StringBuffer();
  for (final char in text.split('')) {
    buffer.write(accentFold[char] ?? char);
  }
  return buffer.toString();
}

final RegExp _whitespacePattern = RegExp(r'\s+');

int levenshtein(String left, String right) {
  var previous = List<int>.generate(right.length + 1, (i) => i);
  for (var row = 1; row <= left.length; row++) {
    final current = <int>[row];
    for (var column = 1; column <= right.length; column++) {
      final substitution = left[row - 1] == right[column - 1] ? 0 : 1;
      current.add(
        math.min(
          math.min(previous[column] + 1, current[column - 1] + 1),
          previous[column - 1] + substitution,
        ),
      );
    }
    previous = current;
  }
  return previous.last;
}

/// Lexique total exact, ou un mot à une édition de « TOTAL » (« TO'AL »,
/// « OTAL », « T0TAL ») : l'OCR abîme surtout cette ligne, imprimée en gras.
/// Le texte compacté porte-t-il une date, sous l'une de ses formes ? Sert de
/// feature au tagger de rôles : c'est le signal le plus direct qu'une ligne
/// est celle de la date.
bool hasDatePattern(String compact) =>
    _datePattern.hasMatch(compact) || _literalDatePattern.hasMatch(compact);

bool containsTotal(String text) {
  if (containsEntry(text, totalWords)) return true;
  return text
      .split(_whitespacePattern)
      .any(
        (token) =>
            token.length >= fuzzyTotalMinTokenLength &&
            token.length <= fuzzyTotalMaxTokenLength &&
            levenshtein(token.toUpperCase(), fuzzyTotalWord) <=
                fuzzyTotalMaxDistance,
      );
}

/// Compare aussi le texte compacté : l'OCR éclate ou fusionne des mots
/// (« Monna ie », « TOTALA PAYER ») et le lexique doit y résister. Les
/// entrées courtes exigent une frontière de mot : « TEL » ne doit pas
/// matcher dans « TORTELL.PESTO ».
bool containsEntry(String text, List<String> lexicon) {
  final upper = foldAccents(text.toUpperCase());
  final compact = upper.replaceAll(_whitespacePattern, '');
  final undotted = upper.replaceAll('.', '');
  final unglyphed = upper
      .replaceAll('0', 'O')
      .replaceAll('1', 'I')
      .replaceAll('5', 'S')
      .replaceAll(_whitespacePattern, '');
  for (final entry in lexicon) {
    final stripped = entry.trim();
    if (stripped.length < 5) {
      final escaped = RegExp.escape(stripped);
      if (RegExp('(?<![A-Z0-9])$escaped(?![A-Z0-9])').hasMatch(upper)) {
        return true;
      }
      if (RegExp('(?<![A-Z])$escaped(?![A-Z])').hasMatch(undotted)) {
        return true;
      }
      continue;
    }
    final boundary = RegExp('(?<![A-Z])${RegExp.escape(entry)}(?![A-Z])');
    if (boundary.hasMatch(upper)) return true;
    if (upper.contains(entry)) continue;
    final squeezed = entry.replaceAll(' ', '');
    if (compact.contains(squeezed) || unglyphed.contains(squeezed)) {
      return true;
    }
  }
  return false;
}

/// Bord gauche minimal des prix : la colonne des prix est à droite du
/// ticket, tout prix nettement à gauche (quantités, codes) n'en fait pas
/// partie.
double? _priceColumnLeft(List<PhysicalLine> lines) {
  final rights = <double>[];
  for (final line in lines) {
    final priced = rightmostPrice(line);
    if (priced != null) rights.add(priced.word.right);
  }
  if (rights.isEmpty) return null;
  rights.sort();
  final medianRight = rights[rights.length ~/ 2];
  return medianRight * 0.75;
}

final RegExp _compactLabelPattern = RegExp(r'EUR|€|\s+');

ExtractedReceipt extract(List<PhysicalLine> lines) {
  final store = lines.isEmpty ? null : lines.first.text;
  final date = findDate(lines);
  final columnLeft = _priceColumnLeft(lines);
  final merged = [for (final line in lines) mergePriceFragments(line)];
  final (totalIndex, total) = _findFinalTotal(merged);

  final items = <ExtractedItem>[];
  String? pendingLabel;
  double? subtotal;
  double? payment;

  for (var index = 0; index < merged.length; index++) {
    final line = merged[index];
    final text = line.text;
    final priced = rightmostPrice(line);

    if (containsEntry(text, subtotalWords) && priced != null) {
      subtotal ??= priced.price;
      pendingLabel = null;
      continue;
    }

    if (containsTotal(text)) {
      pendingLabel = null;
      continue;
    }

    if (containsEntry(text, stopWords)) {
      if (payment == null &&
          priced != null &&
          containsEntry(text, paymentWords)) {
        payment = priced.price;
      }
      pendingLabel = null;
      continue;
    }

    if (totalIndex != null && index > totalIndex) continue;

    if (priced == null) {
      pendingLabel = plausibleLabel(text);
      continue;
    }

    if (columnLeft != null && priced.word.right < columnLeft) {
      pendingLabel = plausibleLabel(text);
      continue;
    }
    if (priced.price == 0) {
      pendingLabel = null;
      continue;
    }

    final label = _labelOf(line, priced.word).trim();

    if (priced.price < 0 || _isDiscountLine(label)) {
      if (items.isNotEmpty) {
        items.last.discount = roundCents(
          items.last.discount + priced.price.abs(),
        );
      }
      pendingLabel = null;
      continue;
    }

    final compactLabel = label.replaceAll(_compactLabelPattern, '');
    final quantityMatch =
        quantityPattern.hasMatch(compactLabel) ||
        weightPattern.hasMatch(compactLabel);
    if (quantityMatch && pendingLabel != null) {
      items.add(
        ExtractedItem(
          name: cleanName(pendingLabel),
          amount: priced.price,
          discount: 0.0,
          lineIndex: index,
        ),
      );
      pendingLabel = null;
      continue;
    }

    if (plausibleLabel(label) == null) {
      if (pendingLabel != null && isDetailLine(label)) {
        items.add(
          ExtractedItem(
            name: cleanName(pendingLabel),
            amount: priced.price,
            discount: 0.0,
            lineIndex: index,
          ),
        );
      }
      pendingLabel = null;
      continue;
    }

    items.add(
      ExtractedItem(
        name: cleanName(label),
        amount: priced.price,
        discount: 0.0,
        lineIndex: index,
      ),
    );
    pendingLabel = null;
  }

  return ExtractedReceipt(
    store: store,
    date: date,
    total: total,
    subtotal: subtotal,
    payment: payment,
    items: items,
    tvaTtcSum: _tvaTtcSum(merged),
    printedCount: printedCount(merged),
    fallbackReferences: _fallbackReferences(merged),
  );
}

bool _isExcludedTotalLine(String text) =>
    containsEntry(text, excludedTotalWords) &&
    !containsEntry(text, taxInclusiveWords);

List<double> _linePrices(PhysicalLine line) => [
  for (final word in line.words) ?parsePrice(word.text),
];

/// Montants de secours pour le checksum, quand le total régulier manque :
/// total sans séparateur décimal sur une ligne « total » pâlie (« 2790 » =
/// 27,90), et prix orphelin d'une ligne sans texte (total en gras dont le
/// libellé a été détruit par l'OCR). Jamais utilisés seuls : une somme
/// d'articles doit retomber dessus au centime.
List<double> _fallbackReferences(List<PhysicalLine> merged) {
  final candidates = <double>[];
  for (final line in merged) {
    final text = line.text;
    if (containsTotal(text) && !_isExcludedTotalLine(text)) {
      if (rightmostPrice(line) == null && _embeddedPrice(text) == null) {
        final match = _missingSeparatorTotalPattern.firstMatch(text);
        if (match != null) {
          candidates.add(roundCents(int.parse(match.group(1)!) / 100));
        }
      }
      continue;
    }
    if (_countLetters(text) >= 2) continue;
    final prices = _linePrices(line);
    if (prices.length == 1 && prices.first > 0) candidates.add(prices.first);
  }
  return candidates;
}

/// Somme des TTC de la table TVA (« B TVA 20.00 5.67 1.13 6.80 ») : une
/// ligne-tableau porte au moins trois montants, le TTC est le plus à droite.
/// Les lignes « TVA 10% : 0,81 » (montant de taxe seul) sont ignorées.
double? _tvaTtcSum(List<PhysicalLine> merged) {
  var total = 0.0;
  var rows = 0;
  for (final line in merged) {
    if (!containsEntry(line.text, tvaWords)) continue;
    final prices = _linePrices(line);
    if (prices.length >= 3) {
      total += prices.last;
      rows++;
    }
  }
  return rows > 0 ? roundCents(total) : null;
}

/// Compteur d'articles imprimé (« 11 ARTICLE(S) »), compacté car l'OCR
/// éclate ou colle les mots.
int? printedCount(List<PhysicalLine> merged) {
  for (final line in merged) {
    final compact = line.text.toUpperCase().replaceAll(_whitespacePattern, '');
    final match = _articleCountPattern.firstMatch(compact);
    if (match != null) return int.parse(match.group(1)!);
  }
  return null;
}

/// Le total à payer est le DERNIER montant d'une ligne « total » du ticket :
/// les enseignes impriment des sous-totaux par rayon (« TOTAL ALIMENTAIRE »)
/// avant le « MONTANT A PAYER » final.
(int?, double?) _findFinalTotal(List<PhysicalLine> merged) {
  int? totalIndex;
  double? total;
  for (var index = 0; index < merged.length; index++) {
    final line = merged[index];
    if (!containsTotal(line.text) || containsEntry(line.text, subtotalWords)) {
      continue;
    }
    if (_isExcludedTotalLine(line.text)) continue;
    final priced = rightmostPrice(line);
    final price = priced?.price ?? _embeddedPrice(line.text);
    if (price != null) {
      totalIndex = index;
      total = price;
    }
  }
  return (totalIndex, total);
}

final RegExp _embeddedPricePattern = RegExp(r'(\d{1,4}[.,]\d{2})\s*€?\s*$');

/// Prix soudé au libellé par l'OCR (« TOTAL A PAYER14.59€ »).
double? _embeddedPrice(String text) {
  final match = _embeddedPricePattern.firstMatch(text);
  if (match == null) return null;
  return double.parse(match.group(1)!.replaceAll(',', '.'));
}

final RegExp _detailTokenPattern = RegExp(
  r'^[\d.,()xX*/€%-]*(?:kg|KG|Kg|EUR|[A-Za-z])?$',
);

/// Ligne de détail sous un libellé : code-barres + prix (« 3177810004089
/// 3.13 »), pesée de balance (« 0,070 10,00 »), décomposition pharmacie
/// (« (2 x 15,92) »), ou rien du tout (prix seul sur sa ligne). Aucun mot :
/// le libellé de l'article est sur la ligne du dessus.
bool isDetailLine(String label) {
  final stripped = label.trim();
  if (stripped.isEmpty) return true;
  if (_countLetters(stripped) > 3) return false;
  return stripped.split(_whitespacePattern).every(_detailTokenPattern.hasMatch);
}

/// Une ligne de remise commence par un mot du lexique (« REMISE FID. »).
/// Un article dont le nom contient « (promotion) » n'en est pas une : seule
/// la position en tête distingue les deux.
bool _isDiscountLine(String label) {
  final upper = label.trim().toUpperCase();
  return discountWords.any(upper.startsWith);
}

final RegExp _quantityPrefixPattern = RegExp(r'^\d{1,2}\s?(?=[A-Za-zÀ-ÿ])');
final RegExp _leaderRunPattern = RegExp(r'[.…]{2,}');
final RegExp _trailingPricePattern = RegExp(r'\s?-?\d{1,4}[.,]\d{2}[€eE]?$');
final RegExp _trailingEuroPattern = RegExp(r'\s+[€eE]$');
final RegExp _multiSpacePattern = RegExp(r'\s{2,}');

/// Libellé prêt pour la catégorisation : sans préfixe quantité, sans points
/// de conduite ni prix unitaire résiduel.
String cleanName(String label) {
  var cleaned = label.trim().replaceFirst(_quantityPrefixPattern, '');
  cleaned = cleaned.replaceAll(_leaderRunPattern, ' ');
  cleaned = cleaned.replaceFirst(_trailingPricePattern, '');
  cleaned = cleaned.replaceFirst(_trailingEuroPattern, '');
  return cleaned.replaceAll(_multiSpacePattern, ' ').trim();
}

String? plausibleLabel(String text) {
  final stripped = text.trim();
  if (_countLetters(stripped) < 2) return null;
  if (containsEntry(stripped, stopWords)) return null;
  return stripped;
}

/// L'année d'une date de ticket, sur deux ou quatre chiffres.
///
/// Compacter les espaces recolle l'heure à la date (« 13/03/17 20:30 »
/// devient « 13/03/1720:30 ») : quatre chiffres qui ne forment pas une année
/// plausible sont donc une année sur deux chiffres suivie de l'heure, et
/// c'est ainsi qu'il faut les relire.
String _yearOf(String digits) {
  var read = digits;
  if (read.length == 4) {
    final year = int.parse(read);
    if (year >= _minYear && year <= _maxYear) return read;
    read = read.substring(0, 2); // l'heure avait été recollée à l'année
  }
  final century = int.parse(read) < _centuryPivot ? 2000 : 1900;
  return '${century + int.parse(read)}';
}

/// L'OCR éclate parfois les dates (« 202 6 », « o9 ») : on compacte les
/// espaces et on ramène o/O vers 0 avant de chercher le motif.
bool _isCalendarDay(String day, String month) {
  final d = int.parse(day);
  final m = int.parse(month);
  return d >= 1 && d <= _maxDay && m >= 1 && m <= _maxMonth;
}

/// Le rang du mois nommé, sur deux chiffres.
String? _monthNumber(String name) {
  final upper = name.toUpperCase();
  for (var index = 0; index < _monthNames.length; index++) {
    for (final entry in _monthNames[index].split('|')) {
      if (upper.startsWith(entry)) return (index + 1).toString().padLeft(2, '0');
    }
  }
  return null;
}

/// L'OCR confond o et 0 dans les chiffres — substitution réservée à cette
/// lecture-ci, elle détruirait les mois en lettres (« OCTOBRE »).
String? _numericDate(String compact) {
  final digitsOnly = compact.replaceAll('o', '0').replaceAll('O', '0');
  for (final match in _datePattern.allMatches(digitsOnly)) {
    final day = match.group(1)!;
    final month = match.group(2)!;
    if (_isCalendarDay(day, month)) {
      final paddedDay = int.parse(day).toString().padLeft(2, '0');
      final paddedMonth = int.parse(month).toString().padLeft(2, '0');
      return '${_yearOf(match.group(3)!)}-$paddedMonth-$paddedDay';
    }
  }
  return null;
}

/// Les mois s'impriment accentués (« août ») : la comparaison se fait sur la
/// forme sans accent, comme le reste des lexiques.
String? _literalDate(String compact) {
  final unaccented = foldAccents(compact);
  for (final match in _literalDatePattern.allMatches(unaccented)) {
    final day = match.group(1)!;
    final month = _monthNumber(match.group(2)!);
    if (month != null && _isCalendarDay(day, month)) {
      final paddedDay = int.parse(day).toString().padLeft(2, '0');
      return '${_yearOf(match.group(3)!)}-$month-$paddedDay';
    }
  }
  return null;
}

/// La date de l'achat, sous l'une de ses formes imprimées.
///
/// Les espaces sont compactés (l'OCR éclate « 202 6 ») et les numéros de
/// téléphone masqués avant toute recherche. La forme numérique prime : elle
/// est la plus courante et la moins ambiguë. La première occurrence *valide*
/// gagne — un jour ou un mois impossible n'est pas une date, et la vraie est
/// souvent plus loin sur la même ligne.
String? findDate(List<PhysicalLine> lines) {
  for (final line in lines) {
    final compact = line.text
        .replaceAll(_whitespacePattern, '')
        .replaceAll(_phonePattern, ' ');
    final found = _numericDate(compact) ?? _literalDate(compact);
    if (found != null) return found;
  }
  return null;
}
