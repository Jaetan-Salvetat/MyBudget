import 'package:mybudget/core/constants/quick_add_schema.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';

final class GeminiNanoChatClient implements AiChatClient {
  const GeminiNanoChatClient({
    required this._channel,
    required this._preference,
    this._service = const GeminiNanoService(),
  });

  static const Set<String> supportedSchemas = {QuickAddSchema.name};

  final GeminiNanoService _service;
  final GeminiNanoChannel _channel;
  final GeminiNanoPreference _preference;

  @override
  Future<String> complete({
    required String prompt,
    required String schemaName,
    required Map<String, dynamic> schema,
    AiImageAttachment? image,
  }) {
    if (!supportedSchemas.contains(schemaName)) {
      throw UnsupportedError(
        'Gemini Nano ne connaît que les schémas $supportedSchemas, '
        'pas "$schemaName"',
      );
    }
    if (image != null) {
      throw UnsupportedError('Gemini Nano n\'accepte pas d\'image ici');
    }

    return _service.generate(
      prompt: prompt,
      schema: schemaName,
      channel: _channel,
      preference: _preference,
    );
  }

  @override
  void close() {}
}
