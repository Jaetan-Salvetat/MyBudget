import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

typedef TempDirectoryResolver = Future<Directory> Function();

abstract interface class ReceiptLineRecognizer {
  Future<List<PhysicalLine>> recognize(Uint8List imageBytes);

  Future<void> close();
}

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

List<PhysicalLine> recognizedLines(RecognizedText recognized) {
  final words = deskewWords(
    recognizedWords(recognized),
    medianAngle(recognizedAngles(recognized)),
  );
  return clusterLines(words);
}

class MlKitReceiptLineRecognizer implements ReceiptLineRecognizer {
  MlKitReceiptLineRecognizer({
    TextRecognizer? recognizer,
    TempDirectoryResolver? tempDirectory,
  }) : _recognizer =
           recognizer ?? TextRecognizer(script: TextRecognitionScript.latin),
       _tempDirectory = tempDirectory ?? getTemporaryDirectory;
  static const String _fileName = 'receipt_scan_pass.jpg';

  final TextRecognizer _recognizer;
  final TempDirectoryResolver _tempDirectory;

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
