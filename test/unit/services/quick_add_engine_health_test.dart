import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/services/ai/quick_add_engine_health.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DateTime now = DateTime(2026, 8, 22, 12);
  late QuickAddEngineHealth health;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
    now = DateTime(2026, 8, 22, 12);
    health = QuickAddEngineHealth(now: () => now);
  });

  Future<bool> fail([
    AiRequestFailure failure = AiRequestFailure.serviceUnavailable,
  ]) => health.recordFailure(failure);

  group('QuickAddEngineHealth', () {
    test('starts healthy', () {
      expect(health.isDegraded, isFalse);
    });

    test('stays healthy below the threshold', () async {
      await fail();
      await fail();

      expect(health.isDegraded, isFalse);
    });

    test('degrades on the third failure', () async {
      await fail();
      await fail();

      expect(await fail(), isTrue, reason: 'la bascule est signalée une fois');
      expect(health.isDegraded, isTrue);
    });

    test('warns only once while it stays degraded', () async {
      await fail();
      await fail();
      await fail();

      expect(await fail(), isFalse);
    });

    test('degrades at once on a revoked key', () async {
      expect(await fail(AiRequestFailure.invalidKey), isTrue);
      expect(health.isDegraded, isTrue);
    });

    test('forgets failures older than the window', () async {
      await fail();
      await fail();
      now = now.add(QuickAddEngineHealth.window + const Duration(minutes: 1));

      expect(await fail(), isFalse);
      expect(health.isDegraded, isFalse);
    });

    test('a success clears the count and lifts the degradation', () async {
      await fail();
      await fail();
      await fail();

      await health.recordSuccess();

      expect(health.isDegraded, isFalse);
    });

    test('survives a restart through the preferences', () async {
      await fail();
      await fail();
      await fail();

      expect(
        QuickAddEngineHealth(now: () => now).isDegraded,
        isTrue,
      );
    });
  });
}
