import 'package:mybudget/core/services/models/model_asset.dart';

/// Le classifieur de lignes étiquette les lignes porteuses de prix du scan
/// et guide le décodeur sous contrainte.
///
/// Le nom de l'asset est lu dans le manifeste, jamais écrit ici : voir
/// [selectModelAsset].
final RegExp lineClassifierAssetPattern = RegExp(
  r'^assets/models/line_clf_v\d+\.json$',
);

Future<String> lineClassifierAssetFromManifest() =>
    modelAssetFromManifest(lineClassifierAssetPattern, 'classifieur de lignes');
