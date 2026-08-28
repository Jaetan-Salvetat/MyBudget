import 'package:mybudget/core/services/models/model_asset.dart';

/// Le répertoire des enseignes : reconnaître le logo au lieu de recopier la
/// ligne que le tagger désigne.
///
/// Le nom de l'asset est lu dans le manifeste, jamais écrit ici : voir
/// [selectModelAsset].
final RegExp storeGazetteerAssetPattern = RegExp(
  r'^assets/models/store_gazetteer_v\d+\.json$',
);

Future<String> storeGazetteerAssetFromManifest() =>
    modelAssetFromManifest(storeGazetteerAssetPattern, "répertoire d'enseignes");
