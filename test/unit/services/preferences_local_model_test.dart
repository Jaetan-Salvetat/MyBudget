import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  group('PreferencesService local model', () {
    group('localModelPath', () {
      test('returns null by default', () {
        expect(PreferencesService.getLocalModelPath(), isNull);
      });

      test('persists and retrieves path', () async {
        await PreferencesService.setLocalModelPath('/data/models/gemma.litertlm');
        expect(
          PreferencesService.getLocalModelPath(),
          '/data/models/gemma.litertlm',
        );
      });

      test('setting null removes the key', () async {
        await PreferencesService.setLocalModelPath('/some/path');
        expect(PreferencesService.getLocalModelPath(), isNotNull);

        await PreferencesService.setLocalModelPath(null);
        expect(PreferencesService.getLocalModelPath(), isNull);
      });
    });

    group('localModelVersion', () {
      test('returns empty string by default', () {
        expect(PreferencesService.getLocalModelVersion(), '');
      });

      test('persists and retrieves version', () async {
        await PreferencesService.setLocalModelVersion('1.0.0');
        expect(PreferencesService.getLocalModelVersion(), '1.0.0');
      });

      test('overwrites previous version', () async {
        await PreferencesService.setLocalModelVersion('1.0.0');
        await PreferencesService.setLocalModelVersion('2.0.0');
        expect(PreferencesService.getLocalModelVersion(), '2.0.0');
      });
    });
  });
}
