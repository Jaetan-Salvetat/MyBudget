import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mybudget/core/services/scan/receipt_image_enhancer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('enhanceReceiptForRetry', () {
    test('une photo trop petite est portée à 2400 px de grand côté', () async {
      final source = img.Image(width: 300, height: 200);
      img.fill(source, color: img.ColorRgb8(120, 120, 120));

      final enhanced = await enhanceReceiptForRetry(
        img.encodeJpg(source, quality: 90),
      );

      final decoded = img.decodeImage(enhanced);
      expect(decoded, isNotNull);
      expect(decoded!.width, 2400);
      expect(decoded.height, 1600);
    });

    test('une image indéchiffrable est signalée, pas avalée', () async {
      expect(
        () => enhanceReceiptForRetry(
          Uint8List.fromList(const [0, 1, 2, 3]),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
