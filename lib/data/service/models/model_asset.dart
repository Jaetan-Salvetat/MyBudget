library;

import 'package:flutter/services.dart';

String selectModelAsset(Iterable<String> assets, RegExp pattern, String label) {
  final matches = assets.where(pattern.hasMatch).toList(growable: false);
  if (matches.isEmpty) {
    throw StateError(
      'Aucun $label dans assets/models/ : lancer ./tool/models/fetch.sh',
    );
  }
  if (matches.length > 1) {
    throw StateError('Plusieurs $label dans assets/models/ : $matches');
  }
  return matches.first;
}

Future<String> modelAssetFromManifest(RegExp pattern, String label) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return selectModelAsset(manifest.listAssets(), pattern, label);
}
