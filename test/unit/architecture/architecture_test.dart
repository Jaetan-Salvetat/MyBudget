import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _dossierRacine = 'lib';
const String _fichierDette = 'test/unit/architecture/dette_architecture.txt';
const String _prefixePaquet = 'package:mybudget/';
const String _coucheInconnue = 'inconnue';

const List<(String, String)> _couchesParChemin = <(String, String)>[
  ('lib/data/model/', 'data.model'),
  ('lib/data/', 'data'),
  ('lib/core/contracts/', 'core.model'),
  ('lib/core/values/', 'core.model'),
  ('lib/core/', 'core'),
  ('lib/ui/shared/', 'ui.shared'),
  ('lib/ui/common/', 'ui.common'),
  ('lib/main.dart', 'racine'),
  ('lib/ui/', 'ui.feature'),
];

const Set<String> _couchesModele = <String>{'core.model', 'data.model'};

const Map<String, Set<String>> _dependancesAutorisees = <String, Set<String>>{
  'core.model': <String>{'core', 'core.model'},
  'core': <String>{'core', 'core.model'},
  'data.model': <String>{'core', 'core.model', 'data.model'},
  'data': <String>{'core', 'core.model', 'data.model', 'data'},
  'ui.shared': <String>{
    'core',
    'core.model',
    'data.model',
    'data',
    'ui.shared',
  },
  'ui.common': <String>{
    'core',
    'core.model',
    'data.model',
    'ui.shared',
    'ui.common',
  },
  'ui.feature': <String>{
    'core',
    'core.model',
    'data.model',
    'data',
    'ui.shared',
    'ui.common',
    'ui.feature',
  },
  'racine': <String>{
    'core',
    'core.model',
    'data.model',
    'data',
    'ui.shared',
    'ui.common',
    'ui.feature',
    'racine',
  },
};

final RegExp _motifImport = RegExp("import '([^']+)'");
final RegExp _motifFlutter = RegExp(
  r'^package:(flutter/|material_ui|frosted_ui|flutter_riverpod|riverpod_)',
);

String _coucheDe(String chemin) {
  for (final (String prefixe, String couche) in _couchesParChemin) {
    if (chemin == prefixe || chemin.startsWith(prefixe)) return couche;
  }
  return _coucheInconnue;
}

String _featureDe(String chemin) {
  final List<String> segments = chemin.split('/');
  if (chemin.startsWith('lib/ui/') && segments.length > 2) return segments[2];
  return segments.last;
}

bool _estEtat(String chemin) {
  final String nom = chemin.split('/').last;
  return nom.endsWith('_provider.dart') ||
      nom.endsWith('_queries.dart') ||
      nom.endsWith('_view_model.dart');
}

List<String> _fichiersSources() {
  return Directory(_dossierRacine)
      .listSync(recursive: true)
      .whereType<File>()
      .map((File fichier) => fichier.path)
      .where(
        (String chemin) =>
            chemin.endsWith('.dart') && !chemin.endsWith('.g.dart'),
      )
      .toList()
    ..sort();
}

Set<String> _violations(List<String> fichiers) {
  final Set<String> trouvees = <String>{};

  for (final String chemin in fichiers) {
    final String source = _coucheDe(chemin);
    final Set<String> autorisees =
        _dependancesAutorisees[source] ?? const <String>{};
    final String contenu = File(chemin).readAsStringSync();

    for (final RegExpMatch correspondance in _motifImport.allMatches(contenu)) {
      final String? cible = correspondance.group(1);
      if (cible == null) continue;

      if (!cible.startsWith(_prefixePaquet)) {
        if (cible.contains('objectbox') &&
            source != 'data' &&
            source != 'data.model') {
          trouvees.add('objectbox|$chemin|$cible');
        }
        if (_couchesModele.contains(source) && _motifFlutter.hasMatch(cible)) {
          trouvees.add('modele_flutter|$chemin|$cible');
        }
        continue;
      }

      final String importe =
          '$_dossierRacine/${cible.substring(_prefixePaquet.length)}';
      if (importe.endsWith('.g.dart')) continue;

      final String couche = _coucheDe(importe);
      if (!autorisees.contains(couche)) {
        trouvees.add('couche|$chemin|$importe');
        continue;
      }

      final bool croiseUneAutreFeature =
          source == 'ui.feature' &&
          couche == 'ui.feature' &&
          _featureDe(chemin) != _featureDe(importe);
      if (croiseUneAutreFeature) {
        final String categorie = _estEtat(importe)
            ? 'etat_croise'
            : 'navigation_croisee';
        trouvees.add('$categorie|$chemin|$importe');
      }
    }
  }

  return trouvees;
}

Set<String> _dette() {
  return File(
    _fichierDette,
  ).readAsLinesSync().where((String ligne) => ligne.trim().isNotEmpty).toSet();
}

List<String> _nouvelles(
  Set<String> violations,
  Set<String> dette,
  String categorie,
) {
  return violations
      .difference(dette)
      .where((String ligne) => ligne.startsWith('$categorie|'))
      .toList()
    ..sort();
}

void main() {
  final List<String> fichiers = _fichiersSources();
  final Set<String> violations = _violations(fichiers);
  final Set<String> dette = _dette();

  group('architecture MVVM', () {
    test('chaque fichier de lib est rattaché à une couche déclarée', () {
      final List<String> orphelins = fichiers
          .where((String chemin) => _coucheDe(chemin) == _coucheInconnue)
          .toList();

      expect(orphelins, isEmpty);
    });

    test('aucune dépendance de couche interdite', () {
      expect(_nouvelles(violations, dette, 'couche'), isEmpty);
    });

    test('objectbox reste confiné à la couche data', () {
      expect(_nouvelles(violations, dette, 'objectbox'), isEmpty);
    });

    test('les modèles ne dépendent pas de Flutter ni de Riverpod', () {
      expect(_nouvelles(violations, dette, 'modele_flutter'), isEmpty);
    });

    test("aucune feature ne lit l'état d'une autre feature", () {
      expect(_nouvelles(violations, dette, 'etat_croise'), isEmpty);
    });

    test("aucune feature n'ouvre directement l'écran d'une autre feature", () {
      expect(_nouvelles(violations, dette, 'navigation_croisee'), isEmpty);
    });

    test('la dette ne contient aucune ligne périmée', () {
      final List<String> perimees = dette.difference(violations).toList()
        ..sort();

      expect(perimees, isEmpty);
    });
  });
}
