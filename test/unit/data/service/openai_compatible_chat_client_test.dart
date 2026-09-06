import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/data/service/ai/ai_chat_client.dart';

class _CountingHttpClient extends http.BaseClient {
  _CountingHttpClient(this.status, this.body, {this.headers = const {}});

  final int status;
  final String body;
  final Map<String, String> headers;

  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      headers: {'content-type': 'application/json', ...headers},
      request: request,
    );
  }
}

void main() {
  Future<Object> failureOf(_CountingHttpClient http) async {
    final client = OpenAiCompatibleChatClient(
      provider: AiProvider.gemini,
      model: AiModel.fallback,
      apiKey: 'AQ.test',
      httpClient: http,
    );
    try {
      await client.complete(
        prompt: 'ping',
        schemaName: 'probe',
        schema: const {'type': 'object'},
      );
      fail('la requête aurait dû échouer');
    } on AiRequestException catch (error) {
      return error.failure;
    } finally {
      client.close();
    }
  }

  test('un quota épuisé remonte tel quel, sans réessai', () async {
    final transport = _CountingHttpClient(
      429,
      '{"error":{"message":"RESOURCE_EXHAUSTED"}}',
      headers: {'retry-after': '42'},
    );

    expect(await failureOf(transport), AiRequestFailure.quotaExceeded);
    expect(transport.calls, 1);
  });

  test('un service indisponible remonte tel quel, sans réessai', () async {
    final transport = _CountingHttpClient(503, '{"error":{"message":"down"}}');

    expect(await failureOf(transport), AiRequestFailure.serviceUnavailable);
    expect(transport.calls, 1);
  });
}
