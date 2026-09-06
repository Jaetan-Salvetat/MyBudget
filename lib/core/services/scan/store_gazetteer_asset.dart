import 'package:mybudget/core/services/models/model_asset.dart';

final RegExp storeGazetteerAssetPattern = RegExp(
  r'^assets/models/store_gazetteer_v\d+\.json$',
);

Future<String> storeGazetteerAssetFromManifest() => modelAssetFromManifest(
  storeGazetteerAssetPattern,
  "répertoire d'enseignes",
);
