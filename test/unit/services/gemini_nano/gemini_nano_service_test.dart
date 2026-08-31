import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/models/gemini_nano_download.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(GeminiNanoService.methodChannelName);
  const downloads = EventChannel(GeminiNanoService.downloadChannelName);
  const service = GeminiNanoService();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final List<MethodCall> calls = <MethodCall>[];

  void answer(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  void emit(List<Object?> events) {
    messenger.setMockStreamHandler(
      downloads,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          for (final event in events) {
            sink.success(event);
          }
          sink.endOfStream();
        },
      ),
    );
  }

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockStreamHandler(downloads, null);
  });

  group('status', () {
    test('traduit l\'identifiant rendu par le natif', () async {
      answer((_) async => GeminiNanoStatus.downloadable.id);

      expect(await service.status(), GeminiNanoStatus.downloadable);
      expect(calls.single.method, GeminiNanoService.statusMethod);
    });

    test('rend unavailable quand le canal échoue', () async {
      answer((_) async => throw PlatformException(code: '8'));

      expect(await service.status(), GeminiNanoStatus.unavailable);
    });

    test('rend unavailable hors Android sans toucher au canal', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      answer((_) async => GeminiNanoStatus.available.id);

      expect(await service.status(), GeminiNanoStatus.unavailable);
      expect(calls, isEmpty);
    });
  });

  group('generate', () {
    test('transmet la saisie et le nom du schéma', () async {
      answer((_) async => '{"category_slug":"divers.autre"}');

      final raw = await service.generate(prompt: 'resto', schema: 'quick_add');

      expect(raw, '{"category_slug":"divers.autre"}');
      expect(calls.single.method, GeminiNanoService.generateMethod);
      expect(calls.single.arguments, {
        GeminiNanoService.promptArgument: 'resto',
        GeminiNanoService.schemaArgument: 'quick_add',
      });
    });

    test('traduit le code d\'erreur natif en panne typée', () async {
      answer(
        (_) async => throw PlatformException(
          code: '${GeminiNanoErrorCode.busy}',
          message: 'quota',
        ),
      );

      expect(
        () => service.generate(prompt: 'resto', schema: 'quick_add'),
        throwsA(
          isA<GeminiNanoException>().having(
            (error) => error.failure,
            'failure',
            GeminiNanoFailure.quotaExceeded,
          ),
        ),
      );
    });

    test('refuse une réponse vide', () async {
      answer((_) async => '');

      expect(
        () => service.generate(prompt: 'resto', schema: 'quick_add'),
        throwsA(
          isA<GeminiNanoException>().having(
            (error) => error.failure,
            'failure',
            GeminiNanoFailure.malformedResponse,
          ),
        ),
      );
    });

    test('signale l\'absence du canal comme indisponibilité', () async {
      messenger.setMockMethodCallHandler(channel, null);

      expect(
        () => service.generate(prompt: 'resto', schema: 'quick_add'),
        throwsA(
          isA<GeminiNanoException>().having(
            (error) => error.failure,
            'failure',
            GeminiNanoFailure.unavailable,
          ),
        ),
      );
    });
  });

  group('download', () {
    test('rend le total au démarrage puis l\'avancement', () async {
      emit([
        {
          GeminiNanoService.eventKey: GeminiNanoService.startedEvent,
          GeminiNanoService.totalBytesKey: 1000,
        },
        {
          GeminiNanoService.eventKey: GeminiNanoService.progressEvent,
          GeminiNanoService.totalBytesKey: 1000,
          GeminiNanoService.downloadedBytesKey: 500,
        },
        {GeminiNanoService.eventKey: GeminiNanoService.completedEvent},
      ]);

      final steps = await service.download().toList();

      expect(steps, hasLength(3));
      expect((steps[0] as GeminiNanoDownloadStarted).totalBytes, 1000);
      expect((steps[1] as GeminiNanoDownloadProgress).ratio, 0.5);
      expect(steps[2], isA<GeminiNanoDownloadCompleted>());
    });

    test('traduit un échec annoncé par le natif', () async {
      emit([
        {
          GeminiNanoService.eventKey: GeminiNanoService.failedEvent,
          GeminiNanoService.codeKey: '${GeminiNanoErrorCode.notEnoughDiskSpace}',
        },
      ]);

      final steps = await service.download().toList();

      expect(
        (steps.single as GeminiNanoDownloadFailed).failure,
        GeminiNanoFailure.outOfSpace,
      );
    });

    test('ignore un événement non reconnu', () async {
      emit([
        {GeminiNanoService.eventKey: 'paused'},
        'texte',
        {GeminiNanoService.eventKey: GeminiNanoService.completedEvent},
      ]);

      final steps = await service.download().toList();

      expect(steps, hasLength(1));
      expect(steps.single, isA<GeminiNanoDownloadCompleted>());
    });

    test('rend un échec hors Android sans écouter le canal', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final steps = await service.download().toList();

      expect(
        (steps.single as GeminiNanoDownloadFailed).failure,
        GeminiNanoFailure.unavailable,
      );
    });
  });
}
