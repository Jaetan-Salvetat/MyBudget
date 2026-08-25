import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import 'local_flow.dart';
import 'ocr_dump.dart';
import 'result_view.dart';
import 'session_stats.dart';
import 'stats_screen.dart';
import 'ticket_detail_screen.dart';

const String _corpusPrefix = 'assets/corpus/';
const String _resultsDirName = 'results';
const String _doneFlagName = 'done.flag';

/// Suite complète : passe chaque image du corpus dans le flow local
/// (OCR + structuration + retry) et dump un JSON par ticket — sortie ML Kit
/// brute au format historique + section `flow` pour le scoring Python.
/// Sources : `input/` poussé via adb (prioritaire, aucun rebuild), sinon les
/// assets embarqués.
class SuiteScreen extends StatefulWidget {
  const SuiteScreen({super.key, this.autoStart = false});

  /// Lance la suite dès l'ouverture : pilotage sans interaction (adb).
  final bool autoStart;

  @override
  State<SuiteScreen> createState() => _SuiteScreenState();
}

class _SuiteEntry {
  const _SuiteEntry({
    required this.image,
    required this.result,
    required this.error,
  });

  final _SuiteImage image;
  final LocalScanResult? result;
  final String? error;
}

class _SuiteScreenState extends State<SuiteScreen> {
  final List<_SuiteEntry> _entries = [];
  bool _running = false;
  bool _done = false;
  int _processed = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runSuite());
    }
  }

  Future<void> _runSuite() async {
    setState(() {
      _running = true;
      _done = false;
      _processed = 0;
      _entries.clear();
    });
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        debugPrint('OCR_HARNESS: FATAL: no external storage directory');
        return;
      }
      final resultsDir = Directory('${externalDir.path}/$_resultsDirName');
      await resultsDir.create(recursive: true);
      final tempDir = await getTemporaryDirectory();

      final inputDir = Directory('${externalDir.path}/input');
      await inputDir.create(recursive: true);
      final fromInput = _imagesFromDir(inputDir);
      final List<_SuiteImage> images = fromInput.isNotEmpty
          ? fromInput
          : await _imagesFromAssets(tempDir);
      setState(() => _total = images.length);

      for (final image in images) {
        try {
          final result = await runLocalFlow(recognizer, image.file, tempDir);
          final dump = ocrDumpJson(
            name: image.name,
            imageWidth: result.pass1.imageWidth,
            imageHeight: result.pass1.imageHeight,
            latencyMs: result.pass1.latencyMs,
            recognized: result.pass1.recognized,
          );
          dump['flow'] = flowJson(result);
          final retry = result.retry;
          if (retry != null) {
            dump['ocrRetry'] = ocrDumpJson(
              name: image.name,
              imageWidth: retry.imageWidth,
              imageHeight: retry.imageHeight,
              latencyMs: retry.latencyMs,
              recognized: retry.recognized,
            );
          }
          await File('${resultsDir.path}/${image.name}.json')
              .writeAsString(jsonEncode(dump));
          sessionStats.record(result);
          _append(
            _SuiteEntry(image: image, result: result, error: null),
            'OK ${image.name}: ${stageName(result.outcome.stage)}'
            '${result.retryUsed ? ' (retry)' : ''}',
          );
        } catch (error, stackTrace) {
          sessionStats.recordFailure();
          _append(
            _SuiteEntry(image: image, result: null, error: '$error'),
            'FAIL ${image.name}: $error',
          );
          debugPrint('suite failure on ${image.name}: $error\n$stackTrace');
        }
        setState(() => _processed++);
      }

      await File('${resultsDir.path}/$_doneFlagName').writeAsString('done');
      setState(() => _done = true);
      debugPrint('OCR_HARNESS: ALL DONE');
    } finally {
      await recognizer.close();
      setState(() => _running = false);
    }
  }

  List<_SuiteImage> _imagesFromDir(Directory inputDir) {
    final files =
        inputDir
            .listSync()
            .whereType<File>()
            .where((f) => RegExp(r'\.(jpg|jpeg|png)$').hasMatch(f.path))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return [
      for (final file in files)
        _SuiteImage(name: file.uri.pathSegments.last, file: file),
    ];
  }

  Future<List<_SuiteImage>> _imagesFromAssets(Directory tempDir) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where((path) => path.startsWith(_corpusPrefix))
        .toList();
    final images = <_SuiteImage>[];
    for (final assetPath in assets) {
      final name = assetPath.substring(_corpusPrefix.length);
      final bytes = await rootBundle.load(assetPath);
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      images.add(_SuiteImage(name: name, file: file));
    }
    return images;
  }

  void _append(_SuiteEntry entry, String message) {
    debugPrint('OCR_HARNESS: $message');
    setState(() => _entries.insert(0, entry));
  }

  Widget _entryTile(_SuiteEntry entry) {
    final result = entry.result;
    if (result == null) {
      return ListTile(
        dense: true,
        leading: const Icon(Icons.error, color: Colors.red, size: 16),
        title: Text(entry.image.name),
        subtitle: Text(entry.error ?? 'échec'),
      );
    }
    final receipt = result.retry?.receipt ?? result.pass1.receipt;
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.circle,
        color: stageColor(result.outcome.stage),
        size: 16,
      ),
      title: Text(entry.image.name),
      subtitle: Text(
        '${stageName(result.outcome.stage)} — '
        '${result.outcome.items.length} articles, '
        'somme ${receipt.itemsSum.toStringAsFixed(2)} / '
        'total ${receipt.total?.toStringAsFixed(2) ?? '—'}'
        '${result.retryUsed ? ' — retry' : ''}',
      ),
      trailing: Text('${result.totalLatencyMs} ms'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(
            name: entry.image.name,
            imageFile: entry.image.file,
            result: result,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _done
              ? 'DONE ($_processed/$_total)'
              : _running
              ? 'Suite… $_processed/$_total'
              : 'Suite complète',
        ),
        actions: [
          IconButton(
            tooltip: 'Stats de session',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StatsScreen())),
            icon: const Icon(Icons.insights),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_running && _total > 0)
            LinearProgressIndicator(value: _processed / _total),
          Expanded(
            child: ListView(
              children: [for (final entry in _entries) _entryTile(entry)],
            ),
          ),
        ],
      ),
      floatingActionButton: _running
          ? null
          : FloatingActionButton.extended(
              onPressed: _runSuite,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lancer'),
            ),
    );
  }
}

class _SuiteImage {
  const _SuiteImage({required this.name, required this.file});

  final String name;
  final File file;
}
