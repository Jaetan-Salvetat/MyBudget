import 'package:mybudget/core/services/models/model_asset.dart';

/// Le tagger de spans dit quels mots de la ligne désignée composent le
/// libellé d'un article : le code imprimé devant et la quantité imprimée
/// derrière n'en font pas partie.
///
/// Le nom de l'asset est lu dans le manifeste, jamais écrit ici : voir
/// [selectModelAsset].
final RegExp labelSpanAssetPattern = RegExp(
  r'^assets/models/label_span_v\d+\.json$',
);

Future<String> labelSpanAssetFromManifest() =>
    modelAssetFromManifest(labelSpanAssetPattern, 'tagger de spans');
