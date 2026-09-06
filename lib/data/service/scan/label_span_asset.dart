import 'package:mybudget/data/service/models/model_asset.dart';

final RegExp labelSpanAssetPattern = RegExp(
  r'^assets/models/label_span_v\d+\.json$',
);

Future<String> labelSpanAssetFromManifest() =>
    modelAssetFromManifest(labelSpanAssetPattern, 'tagger de spans');
