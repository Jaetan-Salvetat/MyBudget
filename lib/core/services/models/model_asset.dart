/// Les modèles embarqués sont publiés hors du dépôt (release GitHub,
/// `tool/models/`) et déposés dans `assets/models/` au build. Chaque version
/// porte son numéro dans le nom du fichier : republier sous le même nom
/// laisserait les installations existantes sur l'ancien modèle, et le cache
/// du runtime ONNX s'indexe dessus.
///
/// Le nom n'est donc écrit nulle part en Dart — il est lu dans le manifeste
/// des assets. Publier n'a ainsi qu'un seul endroit à mettre à jour.
library;

import 'package:flutter/services.dart';

/// L'unique asset qui correspond, ou une erreur qui dit quoi faire.
///
/// Un modèle absent ne se voit pas à la compilation : `pubspec.yaml` déclare
/// `assets/models/` comme dossier, pas fichier par fichier. Oublier
/// `./tool/models/fetch.sh` produirait une app qui n'échoue qu'au premier
/// usage, chez l'utilisateur — autant le dire ici, et clairement.
String selectModelAsset(
  Iterable<String> assets,
  RegExp pattern,
  String label,
) {
  final matches = assets.where(pattern.hasMatch).toList(growable: false);
  if (matches.isEmpty) {
    throw StateError(
      'Aucun $label dans assets/models/ : lancer ./tool/models/fetch.sh',
    );
  }
  if (matches.length > 1) {
    throw StateError('Plusieurs $label dans assets/models/ : $matches');
  }
  return matches.first;
}

Future<String> modelAssetFromManifest(RegExp pattern, String label) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return selectModelAsset(manifest.listAssets(), pattern, label);
}
