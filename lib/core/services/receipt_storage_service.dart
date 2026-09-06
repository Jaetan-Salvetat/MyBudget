import 'dart:io';
import 'dart:typed_data';
import 'package:mybudget/core/time/clock.dart';
import 'package:path_provider/path_provider.dart';

class ReceiptStorageService {
  const ReceiptStorageService(this._clock);
  static const _receiptsDirName = 'receipts';

  final Clock _clock;

  Future<Directory> _getReceiptsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${appDir.path}/$_receiptsDirName');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    return receiptsDir;
  }

  Future<String> saveReceipt(Uint8List imageBytes) async {
    final dir = await _getReceiptsDir();
    final fileName = '${_clock().millisecondsSinceEpoch}.jpg';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  Future<void> deleteReceipt(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Uint8List?> loadReceipt(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }
}
