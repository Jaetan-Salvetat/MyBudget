import 'package:mybudget/core/models/feature_flag.dart';
import 'package:mybudget/core/models/flag_blocklist.dart';

class FeatureFlagResolver {
  const FeatureFlagResolver({required this.buildNumber});

  final int? buildNumber;

  bool resolve({
    required FeatureFlag flag,
    bool? userChoice,
    FlagBlocklist blocklist = FlagBlocklist.empty,
  }) {
    if (blocklist.blocks(flagId: flag.id, buildNumber: buildNumber)) {
      return false;
    }
    return userChoice ?? flag.defaultEnabled;
  }
}
