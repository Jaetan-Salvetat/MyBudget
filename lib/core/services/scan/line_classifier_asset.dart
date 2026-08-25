import 'package:flutter/services.dart';

/// Le classifieur de lignes est publie hors du depot (release GitHub,
/// `tool/line_classifier/`) et depose dans `assets/models/` au build. Chaque
/// reentrainement porte sa version : republier sous le meme nom laisserait
/// les installations existantes sur l'ancien classifieur.
///
/// Le nom n'est pas ecrit ici, il est lu dans le manifeste des assets —
/// publier n'a ainsi qu'un seul endroit a mettre a jour, le fichier depose
/// dans `assets/models/`, au lieu d'une constante Dart et d'un nom de release
/// a garder d'accord.
final RegExp lineClassifierAssetPattern = RegExp(
  r'^assets/models/line_clf_v\d+\.json$',
);

/// Un classifieur absent ne se voit pas a la compilation : `pubspec.yaml`
/// declare `assets/models/` comme dossier, pas fichier par fichier. Oublier
/// `tool/line_classifier/fetch.sh` produirait une app qui echoue seulement au
/// premier ticket scanne — autant le dire ici, et clairement.
Future<String> lineClassifierAssetFromManifest() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final classifiers = manifest
      .listAssets()
      .where(lineClassifierAssetPattern.hasMatch)
      .toList(growable: false);

  if (classifiers.isEmpty) {
    throw StateError(
      'Aucun classifieur de lignes dans assets/models/ : '
      'lancer ./tool/line_classifier/fetch.sh',
    );
  }
  if (classifiers.length > 1) {
    throw StateError(
      'Plusieurs classifieurs de lignes dans assets/models/ : $classifiers',
    );
  }
  return classifiers.first;
}
