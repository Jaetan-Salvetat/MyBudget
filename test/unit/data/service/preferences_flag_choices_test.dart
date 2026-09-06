import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String knownFlag = 'scan';
const String retiredFlag = 'oldExperiment';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  group('choix de fonctionnalités', () {
    test('ignore une fonctionnalité jamais arbitrée', () {
      expect(PreferencesService.getFlagChoice(knownFlag), isNull);
    });

    test('retient le choix dans les deux sens', () async {
      await PreferencesService.setFlagChoice(knownFlag, true);
      expect(PreferencesService.getFlagChoice(knownFlag), isTrue);

      await PreferencesService.setFlagChoice(knownFlag, false);
      expect(PreferencesService.getFlagChoice(knownFlag), isFalse);
    });

    test('efface les choix sans toucher aux autres réglages', () async {
      await PreferencesService.setFlagChoice(knownFlag, true);
      await PreferencesService.setThemeMode(ThemeMode.dark);

      await PreferencesService.clearFlagChoices();

      expect(PreferencesService.getFlagChoice(knownFlag), isNull);
      expect(PreferencesService.getThemeMode(), ThemeMode.dark);
    });

    test('purge les choix des fonctionnalités retirées du registre', () async {
      await PreferencesService.setFlagChoice(knownFlag, true);
      await PreferencesService.setFlagChoice(retiredFlag, true);

      await PreferencesService.purgeUnknownFlagChoices(<String>{knownFlag});

      expect(PreferencesService.getFlagChoice(knownFlag), isTrue);
      expect(PreferencesService.getFlagChoice(retiredFlag), isNull);
    });
  });
}
