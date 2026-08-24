import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import 'local_flow.dart';
import 'ocr_dump.dart';
import 'result_view.dart';

/// Test d'un lot d'images choisies dans la galerie : chaque photo passe le
/// flow local complet, verdict par image et détail au tap. Les dumps JSON
/// (format suite) partent dans `results_gallery/<run>/` pour l'analyse
/// Python via adb pull.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryRun {
  const _GalleryRun({required this.name, required this.result});

  final String name;
  final LocalScanResult result;
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<_GalleryRun> _runs = [];
  bool _running = false;
  int _total = 0;
  String? _error;
  String? _dumpDir;

  Future<void> _pickAndRun() async {
    final List<XFile> images;
    try {
      images = await _picker.pickMultiImage();
    } catch (error) {
      setState(() => _error = 'Galerie indisponible : $error');
      return;
    }
    if (images.isEmpty) return;

    setState(() {
      _running = true;
      _error = null;
      _runs.clear();
      _total = images.length;
    });

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final tempDir = await getTemporaryDirectory();
      final dumpDir = await _createDumpDir();
      for (final (index, image) in images.indexed) {
        final name = image.name.isEmpty ? 'image_$index' : image.name;
        try {
          final result = await runLocalFlow(
            recognizer,
            File(image.path),
            tempDir,
          );
          if (dumpDir != null) {
            await _writeDump(dumpDir, name, result);
          }
          setState(
            () => _runs.add(_GalleryRun(name: name, result: result)),
          );
        } catch (error, stackTrace) {
          debugPrint('gallery failure on $name: $error\n$stackTrace');
          setState(() => _error = 'Échec sur $name : $error');
        }
      }
    } finally {
      await recognizer.close();
      setState(() => _running = false);
    }
  }

  /// Un sous-dossier par run : les lots successifs ne s'écrasent pas.
  Future<Directory?> _createDumpDir() async {
    final Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir == null) return null;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dir = Directory('${externalDir.path}/results_gallery/$stamp');
    await dir.create(recursive: true);
    setState(() => _dumpDir = dir.path);
    return dir;
  }

  Future<void> _writeDump(
    Directory dumpDir,
    String name,
    LocalScanResult result,
  ) async {
    final dump = ocrDumpJson(
      name: name,
      imageWidth: result.pass1.imageWidth,
      imageHeight: result.pass1.imageHeight,
      latencyMs: result.pass1.latencyMs,
      recognized: result.pass1.recognized,
    );
    dump['flow'] = flowJson(result);
    final retry = result.retry;
    if (retry != null) {
      dump['ocrRetry'] = ocrDumpJson(
        name: name,
        imageWidth: retry.imageWidth,
        imageHeight: retry.imageHeight,
        latencyMs: retry.latencyMs,
        recognized: retry.recognized,
      );
    }
    await File('${dumpDir.path}/$name.json').writeAsString(jsonEncode(dump));
  }

  @override
  Widget build(BuildContext context) {
    final validated = _runs
        .where((run) => run.result.outcome.stage != FlowStage.confirm)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _runs.isEmpty && !_running
              ? 'Test depuis la galerie'
              : 'Validés : $validated/${_runs.length}'
                  '${_running ? ' ($_total au total)' : ''}',
        ),
      ),
      body: Column(
        children: [
          if (_running && _total > 0)
            LinearProgressIndicator(value: _runs.length / _total),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          Expanded(
            child: _runs.isEmpty && !_running
                ? const Center(
                    child: Text('Choisis des photos de tickets à tester.'),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 112),
                    children: [
                      for (final run in _runs) _resultTile(run),
                      if (_dumpDir != null && !_running)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Dumps : $_dumpDir',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _running
          ? null
          : FloatingActionButton.extended(
              onPressed: _pickAndRun,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choisir'),
            ),
    );
  }

  Widget _resultTile(_GalleryRun run) {
    final result = run.result;
    final receipt = result.retry?.receipt ?? result.pass1.receipt;
    final stage = result.outcome.stage;
    return ListTile(
      leading: Icon(Icons.circle, color: stageColor(stage), size: 16),
      title: Text(run.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${result.outcome.items.length} articles — '
        'somme ${receipt.itemsSum.toStringAsFixed(2)} / '
        'total ${receipt.total?.toStringAsFixed(2) ?? '—'}'
        '${result.retryUsed ? ' — retry' : ''}',
      ),
      trailing: Text('${result.totalLatencyMs} ms'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(run.name)),
            body: ScanResultView(result: result),
          ),
        ),
      ),
    );
  }
}
