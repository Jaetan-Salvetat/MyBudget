import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/feature_stage.dart';
import 'package:mybudget/core/models/feature_flag.dart';
import 'package:mybudget/core/models/flag_blocklist.dart';
import 'package:mybudget/core/services/feature_flag_resolver.dart';

const int currentBuild = 42;

const FeatureFlag enabledByDefault = FeatureFlag(
  id: 'scan',
  label: 'Scan de tickets',
  description: 'Remplit une dépense depuis la photo d\'un ticket',
  risk: 'Les montants lus peuvent être faux',
  stage: FeatureStage.beta,
  defaultEnabled: true,
);

const FeatureFlag disabledByDefault = FeatureFlag(
  id: 'quickAddAi',
  label: 'Saisie intelligente',
  description: 'Devine le montant et la catégorie depuis une phrase',
  risk: 'La catégorie proposée peut être fausse',
  stage: FeatureStage.experimental,
  defaultEnabled: false,
);

void main() {
  const FeatureFlagResolver resolver = FeatureFlagResolver(
    buildNumber: currentBuild,
  );

  group('FeatureFlagResolver', () {
    test('applique le défaut choisi par l\'app sans arbitrage utilisateur', () {
      expect(resolver.resolve(flag: enabledByDefault), isTrue);
      expect(resolver.resolve(flag: disabledByDefault), isFalse);
    });

    test(
      'laisse le choix utilisateur écraser le défaut dans les deux sens',
      () {
        expect(
          resolver.resolve(flag: enabledByDefault, userChoice: false),
          isFalse,
        );
        expect(
          resolver.resolve(flag: disabledByDefault, userChoice: true),
          isTrue,
        );
      },
    );

    test('n\'éteint rien quand le disjoncteur est injoignable', () {
      expect(resolver.resolve(flag: enabledByDefault), isTrue);
    });

    test('ne coupe que les builds visés par le blocage', () {
      const FlagBlocklist blocklist = FlagBlocklist(<String, Set<int>?>{
        'scan': <int>{currentBuild},
      });

      expect(
        resolver.resolve(flag: enabledByDefault, blocklist: blocklist),
        isFalse,
      );
      expect(
        const FeatureFlagResolver(
          buildNumber: currentBuild + 1,
        ).resolve(flag: enabledByDefault, blocklist: blocklist),
        isTrue,
      );
    });

    test('ne rallume jamais une fonctionnalité bloquée à distance', () {
      const FlagBlocklist blocklist = FlagBlocklist(<String, Set<int>?>{
        'quickAddAi': null,
      });

      for (final bool? choice in <bool?>[null, true, false]) {
        expect(
          resolver.resolve(
            flag: disabledByDefault,
            userChoice: choice,
            blocklist: blocklist,
          ),
          isFalse,
        );
      }
    });

    test('n\'applique que les blocages globaux sans numéro de build', () {
      const FeatureFlagResolver unknownBuild = FeatureFlagResolver(
        buildNumber: null,
      );

      expect(
        unknownBuild.resolve(
          flag: enabledByDefault,
          blocklist: const FlagBlocklist(<String, Set<int>?>{'scan': null}),
        ),
        isFalse,
      );
      expect(
        unknownBuild.resolve(
          flag: enabledByDefault,
          blocklist: const FlagBlocklist(<String, Set<int>?>{
            'scan': <int>{currentBuild},
          }),
        ),
        isTrue,
      );
    });

    test('laisse intactes les fonctionnalités absentes du blocage', () {
      const FlagBlocklist blocklist = FlagBlocklist(<String, Set<int>?>{
        'quickAddAi': null,
      });

      expect(
        resolver.resolve(flag: enabledByDefault, blocklist: blocklist),
        isTrue,
      );
    });
  });
}
