import 'package:flutter/services.dart';

/// Le modèle de lien — celui qui dit à quelle distance au-dessus se trouve le
/// libellé d'un article — est publié hors du dépôt (release GitHub,
/// `tool/line_classifier/`) et déposé dans `assets/models/` au build. Il porte
/// la même version que le classifieur de lignes et le tagger de rôles : ils
/// sont entraînés ensemble et décident ensemble.
///
/// Même mécanique que les deux autres : le nom est lu dans le manifeste des
/// assets, pas écrit ici.
final RegExp labelLinkAssetPattern = RegExp(
  r'^assets/models/label_link_v\d+\.json$',
);

/// Un modèle absent ne se voit pas à la compilation : `pubspec.yaml` déclare
/// `assets/models/` comme dossier, pas fichier par fichier.
Future<String> labelLinkAssetFromManifest() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final models = manifest
      .listAssets()
      .where(labelLinkAssetPattern.hasMatch)
      .toList(growable: false);

  if (models.isEmpty) {
    throw StateError(
      'Aucun modèle de lien dans assets/models/ : '
      'lancer ./tool/line_classifier/fetch.sh',
    );
  }
  if (models.length > 1) {
    throw StateError('Plusieurs modèles de lien dans assets/models/ : $models');
  }
  return models.first;
}
