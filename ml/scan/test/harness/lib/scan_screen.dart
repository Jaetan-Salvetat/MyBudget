import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'local_flow.dart';
import 'result_view.dart';
import 'session_stats.dart';

/// Scan d'un ticket via l'appareil photo : le flow local complet tourne sur
/// la photo et affiche le résultat structuré — le scénario nominal que le
/// corpus FindIt (scans pâlis) ne couvre pas.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  LocalScanResult? _result;
  bool _running = false;
  String? _error;

  Future<void> _scan() async {
    final XFile? photo;
    try {
      photo = await _picker.pickImage(source: ImageSource.camera);
    } catch (error) {
      setState(() => _error = 'Appareil photo indisponible : $error');
      return;
    }
    if (photo == null) return;

    setState(() {
      _running = true;
      _error = null;
      _result = null;
    });
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final tempDir = await getTemporaryDirectory();
      final result = await runLocalFlow(recognizer, File(photo.path), tempDir);
      sessionStats.record(result);
      setState(() => _result = result);
    } catch (error, stackTrace) {
      sessionStats.recordFailure();
      debugPrint('scan failure: $error\n$stackTrace');
      setState(() => _error = 'Échec du scan : $error');
    } finally {
      await recognizer.close();
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un ticket')),
      body: _running
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _running
          ? null
          : FloatingActionButton.extended(
              onPressed: _scan,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Photo'),
            ),
    );
  }

  Widget _buildBody() {
    final error = _error;
    if (error != null) {
      return Center(child: Text(error, textAlign: TextAlign.center));
    }
    final result = _result;
    if (result == null) {
      return const Center(child: Text('Prends un ticket en photo.'));
    }
    return ScanResultView(result: result);
  }
}
