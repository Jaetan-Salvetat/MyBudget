import 'package:mybudget/core/enums/feature_stage.dart';

class FeatureFlag {
  const FeatureFlag({
    required this.id,
    required this.label,
    required this.description,
    required this.risk,
    required this.stage,
    required this.defaultEnabled,
  });

  final String id;
  final String label;
  final String description;
  final String risk;
  final FeatureStage stage;
  final bool defaultEnabled;
}
