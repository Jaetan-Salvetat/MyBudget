import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

const String _corpusPrefix = 'assets/corpus/';
const String _resultsDirName = 'results';
const String _doneFlagName = 'done.flag';

void main() {
  runApp(const OcrHarnessApp());
}

class OcrHarnessApp extends StatelessWidget {
  const OcrHarnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: OcrHarnessScreen());
  }
}

class OcrHarnessScreen extends StatefulWidget {
  const OcrHarnessScreen({super.key});

  @override
  State<OcrHarnessScreen> createState() => _OcrHarnessScreenState();
}

class _OcrHarnessScreenState extends State<OcrHarnessScreen> {
  final List<String> _log = [];
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _runAll();
  }

  Future<void> _runAll() async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        _append('FATAL: no external storage directory');
        return;
      }
      final resultsDir = Directory('${externalDir.path}/$_resultsDirName');
      await resultsDir.create(recursive: true);

      final inputDir = Directory('${externalDir.path}/input');
      if (inputDir.existsSync()) {
        await _runOnFiles(recognizer, inputDir, resultsDir);
      } else {
        await _runOnAssets(recognizer, resultsDir);
      }

      await File('${resultsDir.path}/$_doneFlagName').writeAsString('done');
      setState(() => _done = true);
      _append('ALL DONE');
    } finally {
      await recognizer.close();
    }
  }

  /// Les images poussées via `adb push` dans `input/` priment sur les assets :
  /// changer de corpus ne demande alors aucun rebuild de l'APK.
  Future<void> _runOnFiles(
    TextRecognizer recognizer,
    Directory inputDir,
    Directory resultsDir,
  ) async {
    final files =
        inputDir
            .listSync()
            .whereType<File>()
            .where((f) => RegExp(r'\.(jpg|jpeg|png)$').hasMatch(f.path))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = file.path.split('/').last;
      try {
        final result = await _processFile(recognizer, file, name);
        await File(
          '${resultsDir.path}/$name.json',
        ).writeAsString(jsonEncode(result));
        _append('OK $name (${result['lineCount']} lines)');
      } catch (error, stackTrace) {
        _append('FAIL $name: $error');
        debugPrint('OCR failure on $name: $error\n$stackTrace');
      }
    }
  }

  Future<void> _runOnAssets(
    TextRecognizer recognizer,
    Directory resultsDir,
  ) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final images = manifest
        .listAssets()
        .where((path) => path.startsWith(_corpusPrefix))
        .toList();
    for (final assetPath in images) {
      final name = assetPath.substring(_corpusPrefix.length);
      try {
        final result = await _processAsset(recognizer, assetPath);
        await File(
          '${resultsDir.path}/$name.json',
        ).writeAsString(jsonEncode(result));
        _append('OK $name (${result['lineCount']} lines)');
      } catch (error, stackTrace) {
        _append('FAIL $name: $error');
        debugPrint('OCR failure on $name: $error\n$stackTrace');
      }
    }
  }

  Future<Map<String, dynamic>> _processFile(
    TextRecognizer recognizer,
    File file,
    String name,
  ) async {
    final bytes = await file.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    final int imageWidth = decoded.width;
    final int imageHeight = decoded.height;
    decoded.dispose();

    final stopwatch = Stopwatch()..start();
    final recognized = await recognizer.processImage(
      InputImage.fromFilePath(file.path),
    );
    stopwatch.stop();

    return _resultJson(
      name: name,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      latencyMs: stopwatch.elapsedMilliseconds,
      recognized: recognized,
    );
  }

  Future<Map<String, dynamic>> _processAsset(
    TextRecognizer recognizer,
    String assetPath,
  ) async {
    final bytes = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final name = assetPath.split('/').last;
    final tempFile = File('${tempDir.path}/$name');
    await tempFile.writeAsBytes(bytes.buffer.asUint8List());

    final decoded = await decodeImageFromList(
      bytes.buffer.asUint8List(),
    );
    final int imageWidth = decoded.width;
    final int imageHeight = decoded.height;
    decoded.dispose();

    final stopwatch = Stopwatch()..start();
    final recognized = await recognizer.processImage(
      InputImage.fromFilePath(tempFile.path),
    );
    stopwatch.stop();

    return _resultJson(
      name: name,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      latencyMs: stopwatch.elapsedMilliseconds,
      recognized: recognized,
    );
  }

  Map<String, dynamic> _resultJson({
    required String name,
    required int imageWidth,
    required int imageHeight,
    required int latencyMs,
    required RecognizedText recognized,
  }) {
    int lineCount = 0;
    final blocks = recognized.blocks.map((block) {
      lineCount += block.lines.length;
      return {
        'text': block.text,
        'box': _rect(block.boundingBox),
        'corners': _points(block.cornerPoints),
        'languages': block.recognizedLanguages,
        'lines': block.lines.map(_lineJson).toList(),
      };
    }).toList();

    return {
      'image': name,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'latencyMs': latencyMs,
      'lineCount': lineCount,
      'fullText': recognized.text,
      'blocks': blocks,
    };
  }

  Map<String, dynamic> _lineJson(TextLine line) {
    return {
      'text': line.text,
      'box': _rect(line.boundingBox),
      'corners': _points(line.cornerPoints),
      'confidence': line.confidence,
      'angle': line.angle,
      'elements': line.elements.map(_elementJson).toList(),
    };
  }

  Map<String, dynamic> _elementJson(TextElement element) {
    return {
      'text': element.text,
      'box': _rect(element.boundingBox),
      'corners': _points(element.cornerPoints),
      'confidence': element.confidence,
      'angle': element.angle,
      'symbols': element.symbols
          .map(
            (symbol) => {
              'text': symbol.text,
              'box': _rect(symbol.boundingBox),
              'confidence': symbol.confidence,
            },
          )
          .toList(),
    };
  }

  List<double> _rect(Rect rect) => [rect.left, rect.top, rect.right, rect.bottom];

  List<List<int>> _points(List<Point<int>> points) =>
      points.map((point) => [point.x, point.y]).toList();

  void _append(String message) {
    debugPrint('OCR_HARNESS: $message');
    setState(() => _log.add(message));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_done ? 'DONE' : 'Running…')),
      body: ListView(
        children: [for (final entry in _log) ListTile(title: Text(entry))],
      ),
    );
  }
}
