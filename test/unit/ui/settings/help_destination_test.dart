import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/build_flavor.dart';
import 'package:mybudget/ui/settings/models/help_topic.dart';

void main() {
  group('HelpDestination.isAvailableIn', () {
    test('toutes les destinations sont ouvertes hors du store', () {
      for (final HelpDestination destination in HelpDestination.values) {
        expect(destination.isAvailableIn(BuildFlavor.prod), isTrue);
      }
    });

    test('le store ferme le moteur d\'analyse', () {
      expect(
        HelpDestination.quickAddEngine.isAvailableIn(BuildFlavor.store),
        isFalse,
      );
    });

    test('le store garde les destinations sans rapport', () {
      expect(
        HelpDestination.categories.isAvailableIn(BuildFlavor.store),
        isTrue,
      );
      expect(
        HelpDestination.beneficiaries.isAvailableIn(BuildFlavor.store),
        isTrue,
      );
      expect(HelpDestination.theme.isAvailableIn(BuildFlavor.store), isTrue);
    });
  });
}
