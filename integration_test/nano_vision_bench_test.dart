import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/scan/nano_receipt_prompt.dart';
import 'package:mybudget/core/services/scan/receipt_line_recognizer.dart';
import 'package:path_provider/path_provider.dart';

/// Banc de lecture de tickets : chaque donnée d'un ticket est demandée dans son
/// propre appel, décliné sur la photo, sur la transcription OCR et sur les deux,
/// avec et sans thinking. Les images arrivent par `adb push` dans
/// `files/bench/input`, suivies d'un marqueur `ready` ; les résultats repartent
/// en base64 sur la sortie du test, ligne par ligne, pour survivre à un crash.
const String _inputFolder = 'bench/input';
const String _outputFile = 'bench/nano_bench.json';
const String _readyMarker = 'ready';

const int _longSide = 1024;
const int _dumpChunk = 700;
const int _seed = 42;
const double _extractionHeat = 0.2;

const Duration _inputWait = Duration(minutes: 5);
const Duration _pollDelay = Duration(seconds: 2);

enum Feed {
  image('image'),
  ocr('ocr'),
  hybrid('hybride');

  const Feed(this.id);

  final String id;
}

typedef Section = ({String schema, String task});

const Map<String, Section> _sections = {
  'store': (schema: ReceiptSchema.storeName, task: storeSectionPrompt),
  'date': (schema: ReceiptSchema.dateName, task: dateSectionPrompt),
  'total': (schema: ReceiptSchema.totalName, task: totalSectionPrompt),
  'items': (schema: ReceiptSchema.itemsName, task: itemsSectionPrompt),
};

const String _ocrHead = '\n\n## Ticket transcrit par un OCR\n';

String? _promptFor(Section section, Feed feed, String transcript) {
  if (feed == Feed.image) return section.task;
  if (transcript.isEmpty) return null;
  if (feed == Feed.hybrid) return sectionPrompt(section.task, transcript);

  return '${section.task}$_ocrHead$transcript';
}

Future<Directory> _benchRoot() async {
  final directory = await getExternalStorageDirectory();
  if (directory == null) throw StateError('Aucun stockage externe');
  return directory;
}

Uint8List _resize(img.Image decoded, int longSide) {
  final current = decoded.width > decoded.height ? decoded.width : decoded.height;
  final scaled = current <= longSide
      ? decoded
      : img.copyResize(
          decoded,
          width: (decoded.width * longSide / current).round(),
          height: (decoded.height * longSide / current).round(),
          interpolation: img.Interpolation.cubic,
        );
  return Uint8List.fromList(img.encodeJpg(scaled, quality: 90));
}

void _dump(String marker, String payload) {
  final encoded = base64Encode(utf8.encode(payload));
  for (var start = 0; start < encoded.length; start += _dumpChunk) {
    final end = start + _dumpChunk;
    debugPrintSynchronously(
      '[$marker] ${encoded.substring(start, end > encoded.length ? encoded.length : end)}',
    );
  }
  debugPrintSynchronously('[$marker] fin');
}

Future<List<File>> _awaitPhotos(Directory input) async {
  final deadline = DateTime.now().add(_inputWait);
  while (DateTime.now().isBefore(deadline)) {
    final photos =
        input
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.jpg'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    if (File('${input.path}/$_readyMarker').existsSync()) return photos;
    await Future<void>.delayed(_pollDelay);
  }
  return const [];
}

Future<Map<String, Object?>> _call(
  GeminiNanoService service, {
  required String schema,
  required String prompt,
  required Uint8List? image,
  required bool thinking,
}) async {
  final watch = Stopwatch()..start();
  try {
    final raw = await service.generate(
      prompt: prompt,
      schema: schema,
      channel: GeminiNanoChannel.fallback,
      preference: GeminiNanoPreference.scan,
      image: image,
      temperature: _extractionHeat,
      seed: _seed,
      schemaInPrompt: true,
      thinking: thinking,
    );
    return {'ms': watch.elapsedMilliseconds, 'raw': raw};
  } on GeminiNanoException catch (error) {
    final cause = error.cause;
    return {
      'ms': watch.elapsedMilliseconds,
      'error': error.failure.name,
      'code': cause is PlatformException ? cause.code : null,
    };
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('chaque donnée, chaque modalité, avec et sans thinking', (
    tester,
  ) async {
    const service = GeminiNanoService();

    final status = await service.status(
      GeminiNanoChannel.fallback,
      GeminiNanoPreference.scan,
    );
    final model = await service.modelName(
      GeminiNanoChannel.fallback,
      GeminiNanoPreference.scan,
    );
    debugPrintSynchronously('[bench] statut=${status.id} modèle=$model');
    expect(status.isReady, isTrue, reason: 'Gemini Nano indisponible');

    final root = await _benchRoot();
    final input = Directory('${root.path}/$_inputFolder');
    await input.create(recursive: true);
    debugPrintSynchronously('[bench] attente des tickets dans ${input.path}');

    final photos = await _awaitPhotos(input);
    debugPrintSynchronously('[bench] ${photos.length} tickets');
    expect(photos, isNotEmpty);

    await service.warmUp(GeminiNanoChannel.fallback, GeminiNanoPreference.scan);

    final recognizer = MlKitReceiptLineRecognizer();
    final results = <Map<String, Object?>>[];

    for (final photo in photos) {
      final name = photo.uri.pathSegments.last;
      try {
        final bytes = await photo.readAsBytes();
        final lines = await recognizer.recognize(bytes);
        final transcript = receiptTranscript(lines) ?? '';

        final decoded = img.decodeImage(bytes);
        final image = decoded == null ? null : _resize(decoded, _longSide);
        if (image == null) {
          debugPrintSynchronously('[bench] $name illisible');
          continue;
        }

        final runs = <String, Object?>{};
        for (final section in _sections.entries) {
          for (final feed in Feed.values) {
            final prompt = _promptFor(section.value, feed, transcript);
            for (final thinking in const [false, true]) {
              final key =
                  '${section.key}_${feed.id}${thinking ? '_think' : ''}';
              if (prompt == null) {
                runs[key] = {'error': 'transcriptionIndisponible'};
                continue;
              }
              runs[key] = await _call(
                service,
                schema: section.value.schema,
                prompt: prompt,
                image: feed == Feed.ocr ? null : image,
                thinking: thinking,
              );
            }
          }
        }

        final row = {'ticket': name, 'runs': runs};
        results.add(row);
        _dump('row', jsonEncode(row));
        debugPrintSynchronously('[bench] $name');
      } catch (error, stackTrace) {
        debugPrintSynchronously('[bench] $name a échoué : $error\n$stackTrace');
      }
    }

    await recognizer.close();

    final report = jsonEncode({
      'model': model,
      'status': status.id,
      'results': results,
    });
    final output = File('${root.path}/$_outputFile');
    await output.parent.create(recursive: true);
    await output.writeAsString(report);
    _dump('dump', report);
  }, timeout: const Timeout(Duration(hours: 4)));
}
