import 'package:mybudget/core/services/models/model_asset.dart';

/// Le tagger de rôles donne un rôle à chaque ligne du ticket : il désigne
/// l'enseigne et la ligne de date.
///
/// Le nom de l'asset est lu dans le manifeste, jamais écrit ici : voir
/// [selectModelAsset].
final RegExp roleTaggerAssetPattern = RegExp(
  r'^assets/models/line_roles_v\d+\.json$',
);

Future<String> roleTaggerAssetFromManifest() =>
    modelAssetFromManifest(roleTaggerAssetPattern, 'tagger de rôles');
