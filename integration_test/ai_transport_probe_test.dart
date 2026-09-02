import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/main.dart' as app;

const String _key = String.fromEnvironment('GK');

const Duration _cap = Duration(seconds: 45);

final Uri _endpoint = Uri.parse(
  '${AiProvider.gemini.baseUrl}/chat/completions',
);

String get _payload => jsonEncode({
  'model': AiModel.fallback.id,
  'messages': [
    {'role': 'user', 'content': 'ping'},
  ],
});

Future<void> _timed(String label, Future<String> Function() call) async {
  final watch = Stopwatch()..start();
  try {
    final outcome = await call().timeout(_cap);
    debugPrint('SONDE $label OK en ${watch.elapsed} -> $outcome');
  } catch (error) {
    debugPrint('SONDE $label ECHEC en ${watch.elapsed} -> $error');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('etage 4 : appel identique une fois l\'app demarree', (
    tester,
  ) async {
    app.main();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));

    await _timed('4-DARTIO-DANS-APP', () async {
      final client = HttpClient();
      try {
        final request = await client.postUrl(_endpoint);
        request.headers.set('Authorization', 'Bearer $_key');
        request.headers.set('Content-Type', 'application/json');
        request.write(_payload);
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        return 'HTTP ${response.statusCode} (${body.length} octets)';
      } finally {
        client.close(force: true);
      }
    });

    await _timed('5-NOTRECLIENT-DANS-APP', () async {
      final client = OpenAiCompatibleChatClient(
        provider: AiProvider.gemini,
        model: AiModel.fallback,
        apiKey: _key,
      );
      try {
        return await client.complete(
          prompt: 'Reponds { "ok": true } sans rien ajouter.',
          schemaName: 'probe',
          schema: const {
            'type': 'object',
            'properties': {
              'ok': {'type': 'boolean'},
            },
            'required': ['ok'],
            'additionalProperties': false,
          },
        );
      } finally {
        client.close();
      }
    });
  }, timeout: const Timeout(Duration(seconds: 180)));

  testWidgets('etage 0 : resolution DNS', (tester) async {
    await _timed('0-DNS', () async {
      final addresses = await InternetAddress.lookup(_endpoint.host);
      return addresses.map((a) => a.address).join(', ');
    });
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('etage 1 : dart:io HttpClient brut', (tester) async {
    await _timed('1-DARTIO', () async {
      final client = HttpClient();
      try {
        final request = await client.postUrl(_endpoint);
        request.headers.set('Authorization', 'Bearer $_key');
        request.headers.set('Content-Type', 'application/json');
        request.write(_payload);
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        return 'HTTP ${response.statusCode} (${body.length} octets)';
      } finally {
        client.close(force: true);
      }
    });
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('etage 2 : package:http', (tester) async {
    await _timed('2-PKGHTTP', () async {
      final client = http.Client();
      try {
        final response = await client.post(
          _endpoint,
          headers: {
            'Authorization': 'Bearer $_key',
            'Content-Type': 'application/json',
          },
          body: _payload,
        );
        return 'HTTP ${response.statusCode} (${response.body.length} octets)';
      } finally {
        client.close();
      }
    });
  }, timeout: const Timeout(Duration(seconds: 90)));

  testWidgets('etage 3 : OpenAiCompatibleChatClient', (tester) async {
    await _timed('3-NOTRECLIENT', () async {
      final client = OpenAiCompatibleChatClient(
        provider: AiProvider.gemini,
        model: AiModel.fallback,
        apiKey: _key,
      );
      try {
        return await client.complete(
          prompt: 'Reponds { "ok": true } sans rien ajouter.',
          schemaName: 'probe',
          schema: const {
            'type': 'object',
            'properties': {
              'ok': {'type': 'boolean'},
            },
            'required': ['ok'],
            'additionalProperties': false,
          },
        );
      } finally {
        client.close();
      }
    });
  }, timeout: const Timeout(Duration(seconds: 90)));
}
