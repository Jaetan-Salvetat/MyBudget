import 'dart:convert';
import 'dart:typed_data';

import 'package:openai_dart/openai_dart.dart';

import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';

/// Un appel de complétion contraint par un schéma JSON. L'interface existe
/// pour que rien au-dessus ne dépende du SDK, et pour que les moteurs soient
/// testables sans réseau.
abstract interface class AiChatClient {
  Future<String> complete({
    required String prompt,
    required String schemaName,
    required Map<String, dynamic> schema,
    AiImageAttachment? image,
  });

  void close();
}

/// Une image jointe à la requête. Le type MIME voyage avec les octets : le
/// fournisseur le réclame et il ne se déduit pas d'un [Uint8List].
final class AiImageAttachment {
  const AiImageAttachment._(this.bytes, this.mediaType);

  /// Le seul format que l'app produit : le sélecteur d'image ré-encode en
  /// JPEG dès qu'une qualité de compression lui est donnée.
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
  }) : _model = model.id,
       _client = OpenAIClient.withApiKey(apiKey, baseUrl: provider.baseUrl);

  /// Assez bas pour que la sortie reste reproductible sur une tâche de
  /// classification, pas nul pour ne pas figer les cas ambigus.
  static const double _temperature = 0.1;

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
