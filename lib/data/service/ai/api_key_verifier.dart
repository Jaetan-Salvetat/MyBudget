import 'package:flutter/foundation.dart';

import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/data/model/api_key_check.dart';
import 'package:mybudget/data/service/ai/ai_chat_client.dart';
import 'package:mybudget/data/service/ai/api_key_service.dart';

class ApiKeyVerifier {
  const ApiKeyVerifier({
    required this._clientFactory,
    this.timeout = coldStartTimeout,
  });

  static const Duration coldStartTimeout = Duration(minutes: 2);

  static const String _probePrompt =
      'Réponds { "ok": true } sans rien ajouter.';
  static const Map<String, dynamic> _probeSchema = {
    'type': 'object',
    'properties': {
      'ok': {'type': 'boolean'},
    },
    'required': ['ok'],
    'additionalProperties': false,
  };

  final AiChatClientFactory _clientFactory;
  final Duration timeout;

  Future<ApiKeyCheck> verify({
    required AiProvider provider,
    required AiModel model,
    required String rawKey,
  }) async {
    final key = ApiKeyService.sanitize(rawKey);
    if (key.isEmpty) return _deny(ApiKeyDenialReason.emptyKey, provider);

    final foreignVendor = AiProvider.foreignVendorOf(key);
    if (foreignVendor != null) {
      return _deny(
        ApiKeyDenialReason.foreignProvider,
        provider,
        foreignVendor: foreignVendor,
      );
    }

    final client = _clientFactory(provider, model, key);
    try {
      await client
          .complete(
            prompt: _probePrompt,
            schemaName: 'probe',
            schema: _probeSchema,
          )
          .timeout(timeout);
      return const ApiKeyAccepted();
    } catch (error, stackTrace) {
      debugPrint(
        'Verification de la cle ${provider.id} impossible : '
        '$error\n$stackTrace',
      );
      final failure = AiRequestFailure.from(error);
      if (failure == AiRequestFailure.quotaExceeded) {
        return const ApiKeyAccepted(quotaExhausted: true);
      }
      return _deny(_reasonFor(failure), provider);
    } finally {
      client.close();
    }
  }

  ApiKeyCheck _deny(
    ApiKeyDenialReason reason,
    AiProvider provider, {
    String? foreignVendor,
  }) {
    return ApiKeyDenied(
      reason: reason,
      message: reason.messageFor(provider, foreignVendor: foreignVendor),
    );
  }

  ApiKeyDenialReason _reasonFor(AiRequestFailure failure) {
    return switch (failure) {
      AiRequestFailure.invalidKey => ApiKeyDenialReason.invalidKey,
      AiRequestFailure.permissionDenied => ApiKeyDenialReason.permissionDenied,
      AiRequestFailure.modelNotFound => ApiKeyDenialReason.modelNotFound,
      AiRequestFailure.serviceUnavailable =>
        ApiKeyDenialReason.serviceUnavailable,
      AiRequestFailure.timeout => ApiKeyDenialReason.timeout,
      AiRequestFailure.offline => ApiKeyDenialReason.offline,
      AiRequestFailure.quotaExceeded ||
      AiRequestFailure.malformedResponse ||
      AiRequestFailure.unknown => ApiKeyDenialReason.unknown,
    };
  }
}
