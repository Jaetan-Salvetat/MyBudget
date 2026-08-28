import 'package:mybudget/core/services/models/model_asset.dart';

/// Le modèle de lien dit à quelle distance au-dessus se trouve le libellé
/// d'un article, quand son prix est imprimé seul.
///
/// Le nom de l'asset est lu dans le manifeste, jamais écrit ici : voir
/// [selectModelAsset].
final RegExp labelLinkAssetPattern = RegExp(
  r'^assets/models/label_link_v\d+\.json$',
);

Future<String> labelLinkAssetFromManifest() =>
    modelAssetFromManifest(labelLinkAssetPattern, 'modèle de lien');
