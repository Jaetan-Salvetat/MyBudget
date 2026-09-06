import 'package:mybudget/data/service/models/model_asset.dart';

final RegExp storeClassifierAssetPattern = RegExp(
  r'^assets/models/store_classifier_v\d+\.json$',
);

Future<String> storeClassifierAssetFromManifest() => modelAssetFromManifest(
  storeClassifierAssetPattern,
  "classifieur d'enseigne",
);
