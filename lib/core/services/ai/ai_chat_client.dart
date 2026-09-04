import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart';

import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';

abstract interface class AiChatClient {
  Future<String> complete({
    required String prompt,
    required String schemaName,
    required Map<String, dynamic> schema,
    AiImageAttachment? image,
  });

  void close();
}

final class AiImageAttachment {
  const AiImageAttachment._(this.bytes, this.mediaType);

  const AiImageAttachment.jpeg(Uint8List bytes) : this._(bytes, 'image/jpeg');

  final Uint8List bytes;
  final String mediaType;
}

typedef AiChatClientFactory =
    AiChatClient Function(AiProvider provider, AiModel model, String apiKey);

final class OpenAiCompatibleChatClient implements AiChatClient {
  OpenAiCompatibleChatClient({
    required AiProvider provider,
    required AiModel model,
    required String apiKey,
    http.Client? httpClient,
  }) : _model = model.id,
       _client = OpenAIClient(
         config: OpenAIConfig(
           authProvider: ApiKeyProvider(apiKey),
           baseUrl: provider.baseUrl,
           retryPolicy: _noRetry,
         ),
         httpClient: httpClient,
       );

  static const double _temperature = 0.1;

  static const RetryPolicy _noRetry = RetryPolicy(maxRetries: 0);

  final String _model;
  final OpenAIClient _client;

  @override
  Future<String> complete({
    required String prompt,
    required String schemaName,
    required Map<String, dynamic> schema,
    AiImageAttachment? image,
  }) async {
    try {
      final response = await _client.chat.completions.create(
        ChatCompletionCreateRequest(
          model: _model,
          temperature: _temperature,
          messages: [
            ChatMessage.user([
              ContentPart.text(prompt),
              if (image != null)
                ContentPart.imageBase64(
                  data: base64Encode(image.bytes),
                  mediaType: image.mediaType,
                ),
            ]),
          ],
          responseFormat: ResponseFormat.jsonSchema(
            name: schemaName,
            strict: true,
            schema: schema,
          ),
        ),
      );

      final content = response.text;
      if (content == null || content.isEmpty) {
        throw const AiRequestException(AiRequestFailure.malformedResponse);
      }
      return content;
    } on AiRequestException {
      rethrow;
    } catch (error) {
      throw AiRequestException(AiRequestFailure.from(error), cause: error);
    }
  }

  @override
  void close() => _client.close();
}
