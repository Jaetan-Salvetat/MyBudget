import 'package:flutter/services.dart';

/// Le tagger de rôles est publié hors du dépôt (release GitHub,
/// `tool/line_classifier/`) et déposé dans `assets/models/` au build. Chaque
/// réentraînement porte sa version : republier sous le même nom laisserait
/// les installations existantes sur l'ancien tagger.
///
/// Même mécanique que le classifieur de lignes et le modèle quick-add : le
/// nom est lu dans le manifeste des assets, pas écrit ici.
final RegExp roleTaggerAssetPattern = RegExp(
  r'^assets/models/line_roles_v\d+\.json$',
);

/// Un tagger absent ne se voit pas à la compilation : `pubspec.yaml` déclare
/// `assets/models/` comme dossier, pas fichier par fichier.
Future<String> roleTaggerAssetFromManifest() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final taggers = manifest
      .listAssets()
      .where(roleTaggerAssetPattern.hasMatch)
      .toList(growable: false);

  if (taggers.isEmpty) {
    throw StateError(
      'Aucun tagger de rôles dans assets/models/ : '
      'lancer ./tool/line_classifier/fetch.sh',
    );
  }
  if (taggers.length > 1) {
    throw StateError('Plusieurs taggers de rôles dans assets/models/ : $taggers');
  }
  return taggers.first;
}
