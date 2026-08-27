/// Le répertoire des enseignes, appris de ce que les tickets impriment.
///
/// L'enseigne était une pure **sélection de ligne** : le tagger désigne la
/// ligne la plus probable, le parsing recopie son texte. Deux échecs en
/// découlent — l'abstention sous 0,5 de confiance, et la lecture parasite
/// (`E.Leclerc L`, `ToysMus`, `VOTRE AVIS`).
///
/// Or l'enseigne n'est pas un champ libre, c'est un ensemble quasi clos.
/// Reconnaître au lieu de recopier répare les deux d'un coup : un nom connu se
/// retrouve sous l'OCR abîmé, et se rend sous sa graphie propre. Mesuré côté
/// Python, enseignes justes 469 → 474 sur 500, zéro régression.
///
/// Le répertoire lui-même est construit par `reference/store_gazetteer.py`
/// depuis le seul jeu d'entraînement, et filtré par **discriminance** : un nom
/// n'entre que si le trouver sur une ligne annonce vraiment cette enseigne —
/// c'est ce qui écarte `TOTAL`, enseigne de station-service *et* mot le plus
/// fréquent d'un ticket. Aucune liste noire : le corpus tranche.
///
/// Miroir de `ml/scan/research/reference/store_gazetteer.py`.
library;

import 'structure.dart' show foldAccents, levenshtein;

/// Une entrée courte (`U`, `G20`) ne se cherche pas dans une ligne : elle y
/// apparaîtrait partout. Elle doit être la ligne entière.
const int minContainedLength = 5;

/// Une entrée trop longue pour la fenêtre ne peut pas y tenir ; en deçà, on
/// tolère une édition par tranche de caractères — l'OCR d'un logo abîme
/// rarement plus.
const int fuzzyCharsPerEdit = 6;
const int fuzzyMaxEdits = 3;

final RegExp _nonAlphanumeric = RegExp(r'[^A-Z0-9 ]+');

/// Majuscules sans accent ni ponctuation, espaces réduits.
///
/// Le repli d'accents est celui de `accent_fold.dart`, partagé avec le reste
/// du pipeline : deux tables divergentes feraient reconnaître ici ce qui ne
/// l'est pas là-bas.
String normalizeStore(String text) {
  final folded = foldAccents(text.toUpperCase());
  return folded.replaceAll(_nonAlphanumeric, ' ').split(' ')
      .where((part) => part.isNotEmpty)
      .join(' ');
}

int _tolerance(String entry) {
  final budget = entry.length ~/ fuzzyCharsPerEdit;
  return budget < fuzzyMaxEdits ? budget : fuzzyMaxEdits;
}

/// L'entrée apparaît dans la ligne à quelques éditions près. La fenêtre glisse
/// sur les **mots**, pas sur les caractères : un logo mal lu perd des lettres,
/// il ne se décale pas d'un demi-mot.
bool fuzzyContains(String line, String entry) {
  final budget = _tolerance(entry);
  if (budget == 0) return false;
  final words = line.split(' ');
  for (var start = 0; start < words.length; start++) {
    var window = '';
    for (var end = start; end < words.length; end++) {
      window = window.isEmpty ? words[end] : '$window ${words[end]}';
      if (window.length > entry.length + budget) break;
      final gap = (window.length - entry.length).abs();
      if (gap <= budget && levenshtein(window, entry) <= budget) return true;
    }
  }
  return false;
}

/// Les noms d'enseigne connus, du plus long au plus court — la ligne
/// « CARREFOUR MARKET » doit rendre l'enseigne complète, pas « CARREFOUR ».
class Gazetteer {
  Gazetteer(this.canonical)
    : keys = canonical.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));

  final Map<String, String> canonical;
  final List<String> keys;

  /// L'enseigne que cette ligne nomme, ou null. Trois passes, de la plus sûre
  /// à la moins sûre : la ligne entière, le nom contenu, le nom approché.
  String? match(String text) {
    final line = normalizeStore(text);
    if (line.isEmpty) return null;
    for (final key in keys) {
      if (key == line) return canonical[key];
    }
    for (final key in keys) {
      if (key.length >= minContainedLength && line.contains(key)) {
        return canonical[key];
      }
    }
    for (final key in keys) {
      if (key.length >= minContainedLength && fuzzyContains(line, key)) {
        return canonical[key];
      }
    }
    return null;
  }
}
