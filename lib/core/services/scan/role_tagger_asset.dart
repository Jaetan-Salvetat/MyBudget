import 'package:mybudget/core/services/models/model_asset.dart';

final RegExp roleTaggerAssetPattern = RegExp(
  r'^assets/models/line_roles_v\d+\.json$',
);

Future<String> roleTaggerAssetFromManifest() =>
    modelAssetFromManifest(roleTaggerAssetPattern, 'tagger de rôles');
