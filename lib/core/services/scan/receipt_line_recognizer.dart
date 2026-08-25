import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

typedef TempDirectoryResolver = Future<Directory> Function();

/// Reconstruit les lignes physiques d'un ticket depuis une photo. Abstrait
/// pour que le flow se teste sans la reconnaissance de texte du système.
abstract interface class ReceiptLineRecognizer {
  Future<List<PhysicalLine>> recognize(Uint8List imageBytes);

  Future<void> close();
}

/// Mots au format du pipeline, depuis la sortie ML Kit brute.
List<Word> recognizedWords(RecognizedText recognized) => [
  for (final block in recognized.blocks)
    for (final line in block.lines)
      for (final element in line.elements)
        Word(
          text: element.text,
          left: element.boundingBox.left,
          top: element.boundingBox.top,
          right: element.boundingBox.right,
          bottom: element.boundingBox.bottom,
          confidence: element.confidence,
        ),
];

List<double> recognizedAngles(RecognizedText recognized) => [
  for (final block in recognized.blocks)
    for (final line in block.lines)
      if (line.angle != null) line.angle!,
];

/// Lignes physiques du ticket : déskew des mots ML Kit puis clustering.
List<PhysicalLine> recognizedLines(RecognizedText recognized) {
  final words = deskewWords(
    recognizedWords(recognized),
    medianAngle(recognizedAngles(recognized)),
  );
  return clusterLines(words);
}

/// ML Kit lit un fichier, pas un tampon : la photo est déposée dans le
/// dossier temporaire le temps de la passe, puis effacée.
class MlKitReceiptLineRecognizer implements ReceiptLineRecognizer {
  static const String _fileName = 'receipt_scan_pass.jpg';

  final TextRecognizer _recognizer;
  final TempDirectoryResolver _tempDirectory;

  MlKitReceiptLineRecognizer({
    TextRecognizer? recognizer,
    TempDirectoryResolver? tempDirectory,
  }) : _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin),
       _tempDirectory = tempDirectory ?? getTemporaryDirectory;

  @override
  Future<List<PhysicalLine>> recognize(Uint8List imageBytes) async {
    final directory = await _tempDirectory();
    final file = File('${directory.path}/$_fileName');
    await file.writeAsBytes(imageBytes, flush: true);
    try {
      final recognized = await _recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      return recognizedLines(recognized);
    } finally {
      if (file.existsSync()) await file.delete();
    }
  }

  @override
  Future<void> close() => _recognizer.close();
}
