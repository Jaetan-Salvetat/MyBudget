import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/ai_request_failure.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/core/services/scan/cloud_receipt_reader.dart';

class _StubChatClient implements AiChatClient {
  _StubChatClient({this.answer, this.failure});

  final String? answer;
  final AiRequestFailure? failure;

  String? askedPrompt;
  String? askedSchemaName;
  AiImageAttachment? askedImage;
  bool closed = false;

  @override
  Future<String> complete({
    required String prompt,
    required String schemaName,
    required Map<String, dynamic> schema,
    AiImageAttachment? image,
  }) async {
    askedPrompt = prompt;
    askedSchemaName = schemaName;
    askedImage = image;
    if (failure != null) throw AiRequestException(failure!);
    return answer!;
  }

  @override
  void close() => closed = true;
}

final Uint8List _photo = Uint8List.fromList([1, 2, 3]);
final Uint8List _jpeg = Uint8List.fromList([4, 5, 6]);

Future<Uint8List> _fakePrepare(Uint8List bytes) async => _jpeg;

Future<Uint8List> _failingPrepare(Uint8List bytes) async =>
    throw const FormatException('image indéchiffrable');

String _payload({
  Object? store = 'CARREFOUR',
  Object? date = '2026-08-01',
  Object? total = 5.0,
  List<Object?> items = const [
    {'name': 'PAIN', 'amount': 2.0, 'discount': 0.0},
    {'name': 'LAIT', 'amount': 3.0, 'discount': 0.0},
  ],
}) {
  return jsonEncode({
    'store': store,
    'date': date,
    'total': total,
    'items': items,
  });
}

CloudReceiptReader _readerOf(
  _StubChatClient client, {
  ReceiptImagePreparer prepare = _fakePrepare,
}) {
  return CloudReceiptReader(client: client, prepare: prepare);
}

void main() {
  group('CloudReceiptReader', () {
    test('rend le ticket lu par le modèle distant', () async {
      final client = _StubChatClient(answer: _payload());

      final scan = await _readerOf(client).read(_photo);

      expect(scan.store, 'CARREFOUR');
      expect(scan.date, '2026-08-01');
      expect(scan.total, 5.0);
      expect([for (final item in scan.items) item.name], ['PAIN', 'LAIT']);
      expect(scan.verified, isTrue);
    });

    test('envoie la photo préparée en JPEG au modèle', () async {
      final client = _StubChatClient(answer: _payload());

      await _readerOf(client).read(_photo);

      expect(client.askedImage?.bytes, _jpeg);
      expect(client.askedImage?.mediaType, 'image/jpeg');
      expect(client.askedPrompt, isNotEmpty);
    });

    test('un total qui ne tombe pas juste reste non vérifié', () async {
      final client = _StubChatClient(answer: _payload(total: 9.0));

      final scan = await _readerOf(client).read(_photo);

      expect(scan.verified, isFalse);
    });

    test('une requête refusée remonte la panne du service', () async {
      final client = _StubChatClient(failure: AiRequestFailure.invalidKey);

      await expectLater(
        _readerOf(client).read(_photo),
        throwsA(
          isA<ScanRemoteException>().having(
            (error) => error.failure,
            'failure',
            AiRequestFailure.invalidKey,
          ),
        ),
      );
    });

    test('une panne réseau garde sa cause', () async {
      final client = _StubChatClient(failure: AiRequestFailure.offline);

      await expectLater(
        _readerOf(client).read(_photo),
        throwsA(
          isA<ScanRemoteException>().having(
            (error) => error.message,
            'message',
            AiRequestFailure.offline.label,
          ),
        ),
      );
    });

    test('une réponse illisible se dit comme telle', () async {
      final client = _StubChatClient(answer: 'pas du json');

      await expectLater(
        _readerOf(client).read(_photo),
        throwsA(isA<ScanNoItemsException>()),
      );
    });

    test('un ticket sans article se dit comme tel', () async {
      final client = _StubChatClient(answer: _payload(items: const []));

      await expectLater(
        _readerOf(client).read(_photo),
        throwsA(isA<ScanNoItemsException>()),
      );
    });

    test('une photo impossible à préparer ne part pas au réseau', () async {
      final client = _StubChatClient(answer: _payload());

      await expectLater(
        _readerOf(client, prepare: _failingPrepare).read(_photo),
        throwsA(isA<ScanUnreadablePhotoException>()),
      );
      expect(client.askedImage, isNull);
    });
  });
}
