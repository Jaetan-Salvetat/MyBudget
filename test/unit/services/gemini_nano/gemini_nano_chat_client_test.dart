import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/quick_add_schema.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/ai/gemini_nano_chat_client.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';

class _StubService extends GeminiNanoService {
  _StubService(this.answer);

  final String answer;

  String? prompt;
  String? schema;

  @override
  Future<String> generate({
    required String prompt,
    required String schema,
  }) async {
    this.prompt = prompt;
    this.schema = schema;
    return answer;
  }
}

void main() {
  const String response = '{"category_slug":"divers.autre"}';

  test('transmet la saisie et le nom du schéma au service', () async {
    final service = _StubService(response);
    final client = GeminiNanoChatClient(service: service);

    final raw = await client.complete(
      prompt: 'resto italien',
      schemaName: QuickAddSchema.name,
      schema: const {},
    );

    expect(raw, response);
    expect(service.prompt, 'resto italien');
    expect(service.schema, QuickAddSchema.name);
  });

  test('refuse un schéma que le natif ne connaît pas', () {
    final client = GeminiNanoChatClient(service: _StubService(response));

    expect(
      () => client.complete(
        prompt: 'resto',
        schemaName: 'receipt',
        schema: const {},
      ),
      throwsUnsupportedError,
    );
  });

  test('refuse une image', () {
    final client = GeminiNanoChatClient(service: _StubService(response));

    expect(
      () => client.complete(
        prompt: 'ticket',
        schemaName: QuickAddSchema.name,
        schema: const {},
        image: AiImageAttachment.jpeg(Uint8List(0)),
      ),
      throwsUnsupportedError,
    );
  });
}
