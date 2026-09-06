import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/build_flavor.dart';

void main() {
  final List<BuildFlavor> sideloadedFlavors = BuildFlavor.values
      .where((BuildFlavor flavor) => flavor != BuildFlavor.store)
      .toList();

  group('BuildFlavor.fromId', () {
    test('reconnaît chaque saveur par son identifiant Gradle', () {
      for (final BuildFlavor flavor in BuildFlavor.values) {
        expect(BuildFlavor.fromId(flavor.id), flavor);
      }
    });

    test('retombe sur dev quand la saveur est absente ou inconnue', () {
      expect(BuildFlavor.fromId(null), BuildFlavor.fallback);
      expect(BuildFlavor.fromId(''), BuildFlavor.fallback);
      expect(BuildFlavor.fromId('staging'), BuildFlavor.fallback);
    });

    test('les identifiants sont uniques', () {
      final Set<String> ids = BuildFlavor.values
          .map((BuildFlavor flavor) => flavor.id)
          .toSet();

      expect(ids, hasLength(BuildFlavor.values.length));
    });
  });

  group('capacités', () {
    test('seule la saveur store masque le choix du moteur d\'analyse', () {
      expect(BuildFlavor.store.exposesQuickAddEngineSettings, isFalse);

      for (final BuildFlavor flavor in sideloadedFlavors) {
        expect(flavor.exposesQuickAddEngineSettings, isTrue);
      }
    });
  });
}
