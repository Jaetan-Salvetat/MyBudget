import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mybudget/core/models/flag_blocklist.dart';
import 'package:mybudget/core/services/flag_blocklist_service.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String scanBlocked = '{"blocked": [{"id": "scan"}]}';
const String nothingBlocked = '{"blocked": []}';
const int anyBuild = 42;

FlagBlocklistService serviceReturning(
  http.Response Function(http.Request request) handler,
) {
  return FlagBlocklistService(
    httpClient: MockClient((http.Request request) async {
      return handler(request);
    }),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();
  });

  group('FlagBlocklistService', () {
    test('ne bloque rien tant qu\'aucune liste n\'a été reçue', () {
      final FlagBlocklistService service = serviceReturning(
        (_) => http.Response(nothingBlocked, 200),
      );

      expect(
        service.cached().blocks(flagId: 'scan', buildNumber: anyBuild),
        isFalse,
      );
    });

    test('retient la liste reçue pour les démarrages suivants', () async {
      final FlagBlocklistService service = serviceReturning(
        (_) => http.Response(scanBlocked, 200),
      );

      final FlagBlocklist refreshed = await service.refresh();

      expect(refreshed.blocks(flagId: 'scan', buildNumber: anyBuild), isTrue);
      expect(
        service.cached().blocks(flagId: 'scan', buildNumber: anyBuild),
        isTrue,
      );
    });

    test('interroge bien le domaine du disjoncteur', () async {
      late Uri requested;
      final FlagBlocklistService service = serviceReturning((
        http.Request request,
      ) {
        requested = request.url;
        return http.Response(nothingBlocked, 200);
      });

      await service.refresh();

      expect(requested, Uri.parse(flagBlocklistEndpoint));
    });

    test('conserve le dernier blocage connu quand le serveur échoue', () async {
      await PreferencesService.setFlagBlocklist(scanBlocked);
      final FlagBlocklistService service = serviceReturning(
        (_) => http.Response('', 500),
      );

      final FlagBlocklist blocklist = await service.refresh();

      expect(blocklist.blocks(flagId: 'scan', buildNumber: anyBuild), isTrue);
    });

    test('conserve le dernier blocage connu quand le réseau tombe', () async {
      await PreferencesService.setFlagBlocklist(scanBlocked);
      final FlagBlocklistService service = serviceReturning(
        (_) => throw http.ClientException('réseau indisponible'),
      );

      final FlagBlocklist blocklist = await service.refresh();

      expect(blocklist.blocks(flagId: 'scan', buildNumber: anyBuild), isTrue);
    });

    test('n\'écrase pas le cache avec une charge utile corrompue', () async {
      await PreferencesService.setFlagBlocklist(scanBlocked);
      final FlagBlocklistService service = serviceReturning(
        (_) => http.Response('{"blocked": "oups"}', 200),
      );

      final FlagBlocklist blocklist = await service.refresh();

      expect(blocklist.blocks(flagId: 'scan', buildNumber: anyBuild), isTrue);
      expect(PreferencesService.getFlagBlocklist(), scanBlocked);
    });
  });
}
