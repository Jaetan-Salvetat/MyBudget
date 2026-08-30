import 'package:mybudget/core/services/models/model_asset.dart';

final RegExp labelLinkAssetPattern = RegExp(
  r'^assets/models/label_link_v\d+\.json$',
);

Future<String> labelLinkAssetFromManifest() =>
    modelAssetFromManifest(labelLinkAssetPattern, 'modèle de lien');
