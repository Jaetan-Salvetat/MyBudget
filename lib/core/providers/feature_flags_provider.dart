import 'package:http/http.dart' as http;
import 'package:mybudget/core/constants/feature_flags.dart';
import 'package:mybudget/core/models/feature_flag.dart';
import 'package:mybudget/core/models/flag_blocklist.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/feature_flag_resolver.dart';
import 'package:mybudget/core/services/flag_blocklist_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feature_flags_provider.g.dart';

@Riverpod(keepAlive: true)
List<FeatureFlag> featureFlagRegistry(Ref ref) => featureFlags;

@Riverpod(keepAlive: true)
FlagBlocklistService flagBlocklistService(Ref ref) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return FlagBlocklistService(httpClient: client);
}

@Riverpod(keepAlive: true)
class FlagBlocklistNotifier extends _$FlagBlocklistNotifier {
  @override
  FlagBlocklist build() => ref.watch(flagBlocklistServiceProvider).cached();

  Future<void> refresh() async {
    state = await ref.read(flagBlocklistServiceProvider).refresh();
  }
}

@Riverpod(keepAlive: true)
class FeatureFlagChoicesNotifier extends _$FeatureFlagChoicesNotifier {
  @override
  Map<String, bool> build() {
    return <String, bool>{
      for (final FeatureFlag flag in ref.watch(featureFlagRegistryProvider))
        if (PreferencesService.getFlagChoice(flag.id) case final bool choice)
          flag.id: choice,
    };
  }

  Future<void> choose(String flagId, bool enabled) async {
    await PreferencesService.setFlagChoice(flagId, enabled);
    state = <String, bool>{...state, flagId: enabled};
  }

  Future<void> resetAll() async {
    await PreferencesService.clearFlagChoices();
    state = const <String, bool>{};
  }
}

@Riverpod(keepAlive: true)
FeatureFlagResolver featureFlagResolver(Ref ref) {
  return FeatureFlagResolver(buildNumber: ref.watch(appBuildCodeProvider));
}

@Riverpod(keepAlive: true)
bool featureEnabled(Ref ref, FeatureFlag flag) {
  return ref
      .watch(featureFlagResolverProvider)
      .resolve(
        flag: flag,
        userChoice: ref.watch(featureFlagChoicesProvider)[flag.id],
        blocklist: ref.watch(flagBlocklistProvider),
      );
}

@Riverpod(keepAlive: true)
bool featureBlocked(Ref ref, FeatureFlag flag) {
  return ref
      .watch(flagBlocklistProvider)
      .blocks(flagId: flag.id, buildNumber: ref.watch(appBuildCodeProvider));
}
