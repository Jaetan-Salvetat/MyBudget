import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/models/api_key_check.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/ai/api_key_verifier.dart';
import 'package:openai_dart/openai_dart.dart';

class _StubChatClient implements AiChatClient {
  _StubChatClient({this.error});

  static const String response = '{"ok":true}';
  final Object? error;

  int calls = 0;
  bool closed = false;

  @override
  Future<String> complete({
    required String prompt,
    required String schemaName,
    required Map<String, dynamic> schema,
    AiImageAttachment? image,
  }) async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return response;
  }

  @override
  void close() => closed = true;
}

void main() {
  const validKey = 'AIzaSyA01234567890123456789012345678901';

  late _StubChatClient client;
  late ApiKeyVerifier verifier;
  AiModel? requestedModel;

  void useClient(_StubChatClient stub) {
    client = stub;
    verifier = ApiKeyVerifier(
      clientFactory: (_, model, _) {
        requestedModel = model;
        return stub;
      },
    );
  }

  setUp(() {
    requestedModel = null;
    useClient(_StubChatClient());
  });

  Future<ApiKeyCheck> verify(String key, {AiModel model = AiModel.fallback}) =>
      verifier.verify(
        provider: AiProvider.gemini,
        model: model,
        rawKey: key,
      );

  group('ApiKeyVerifier local checks', () {
    test('probes the service with the chosen model', () async {
      await verify(validKey, model: AiModel.flash37);

      expect(requestedModel, AiModel.flash37);
    });

    test('accepts a key padded with whitespace', () async {
      expect(await verify('  $validKey \n'), isA<ApiKeyAccepted>());
    });

    test('refuses a malformed key without calling the service', () async {
      final check = await verify('nope');

      expect(check, isA<ApiKeyDenied>());
      expect(
        (check as ApiKeyDenied).reason,
        ApiKeyDenialReason.invalidFormat,
      );
      expect(client.calls, 0);
    });

    test('names the vendor when the key comes from another service', () async {
      final check = await verify('sk-ant-api03-abcdef');

      expect(check, isA<ApiKeyDenied>());
      final denied = check as ApiKeyDenied;
      expect(denied.reason, ApiKeyDenialReason.foreignProvider);
      expect(denied.message, contains('Anthropic'));
      expect(client.calls, 0);
    });
  });

  group('ApiKeyVerifier service answers', () {
    test('accepts a key the service answered for', () async {
      expect(await verify(validKey), isA<ApiKeyAccepted>());
      expect(client.calls, 1);
    });

    test('closes the client whatever the answer', () async {
      await verify(validKey);
      expect(client.closed, isTrue);
    });

    test('accepts an authenticated key whose quota is spent', () async {
      useClient(
        _StubChatClient(
          error: const RateLimitException(message: 'RESOURCE_EXHAUSTED'),
        ),
      );

      final check = await verify(validKey);

      expect(check, isA<ApiKeyAccepted>());
      expect((check as ApiKeyAccepted).quotaExhausted, isTrue);
    });

    test('rejects a key the service does not recognise', () async {
      useClient(
        _StubChatClient(
          error: const AuthenticationException(message: 'invalid'),
        ),
      );

      final check = await verify(validKey);

      expect((check as ApiKeyDenied).reason, ApiKeyDenialReason.invalidKey);
    });

    test('rejects a key without access to the API', () async {
      useClient(
        _StubChatClient(
          error: const PermissionDeniedException(message: 'denied'),
        ),
      );

      final check = await verify(validKey);

      final denied = check as ApiKeyDenied;
      expect(denied.reason, ApiKeyDenialReason.permissionDenied);
      expect(denied.message, contains('Google AI Studio'));
    });

    test('reports a connection error rather than storing anything', () async {
      useClient(
        _StubChatClient(error: const SocketException('no route')),
      );

      final check = await verify(validKey);

      final denied = check as ApiKeyDenied;
      expect(denied.reason, ApiKeyDenialReason.offline);
      expect(
        denied.message,
        'Pas de connexion internet. Impossible de vérifier la clé.',
      );
    });

    test('reports an unavailable service as retryable', () async {
      useClient(
        _StubChatClient(
          error: const InternalServerException(message: 'boom', statusCode: 503),
        ),
      );

      final check = await verify(validKey);

      expect(
        (check as ApiKeyDenied).reason,
        ApiKeyDenialReason.serviceUnavailable,
      );
    });
  });

  group('AiRequestFailure mapping', () {
    test('reads a Gemini invalid key sent as a 400', () {
      const error = BadRequestException(
        message: 'API key not valid',
        code: 'API_KEY_INVALID',
      );

      expect(AiRequestFailure.from(error), AiRequestFailure.invalidKey);
    });

    test('leaves an unrelated 400 unknown', () {
      const error = BadRequestException(message: 'bad schema');

      expect(AiRequestFailure.from(error), AiRequestFailure.unknown);
    });

    test('treats a revoked key as reason to degrade at once', () {
      expect(AiRequestFailure.invalidKey.revokesKey, isTrue);
      expect(AiRequestFailure.permissionDenied.revokesKey, isTrue);
      expect(AiRequestFailure.timeout.revokesKey, isFalse);
    });
  });
}
