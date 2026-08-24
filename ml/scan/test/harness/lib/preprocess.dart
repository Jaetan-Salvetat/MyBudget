
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const int _retryLongSide = 2400;
const int _unsharpRadius = 2;
const double _unsharpAmount = 1.5;
const int _jpegQuality = 90;

/// Prétraitement du retry quand le checksum échoue : autocontrast + unsharp
/// + upscale 2400 px. Récupère ~10 % des échecs de la première passe OCR
/// (mesuré sur corpus, voir ml/scan/README.md). Tourne dans un isolate :
/// plusieurs secondes de calcul pur Dart sur une photo de téléphone.
Future<Uint8List> enhanceForRetry(Uint8List bytes) {
  return compute(_enhance, bytes);
}

Uint8List _enhance(Uint8List bytes) {
  var image = img.decodeImage(bytes);
  if (image == null) {
    throw const FormatException('image indéchiffrable pour le prétraitement');
  }
  final longSide =
      image.width > image.height ? image.width : image.height;
  if (longSide < _retryLongSide) {
    final scale = _retryLongSide / longSide;
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.cubic,
    );
  }
  image = img.normalize(image, min: 0, max: 255);
  image = _unsharpMask(image);
  return Uint8List.fromList(img.encodeJpg(image, quality: _jpegQuality));
}

img.Image _unsharpMask(img.Image source) {
  final blurred = img.gaussianBlur(source.clone(), radius: _unsharpRadius);
  final result = source.clone();
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final original = source.getPixel(x, y);
      final soft = blurred.getPixel(x, y);
      final target = result.getPixel(x, y);
      target.r = _sharpen(original.r, soft.r);
      target.g = _sharpen(original.g, soft.g);
      target.b = _sharpen(original.b, soft.b);
    }
  }
  return result;
}

num _sharpen(num original, num blurred) {
  final value = original + _unsharpAmount * (original - blurred);
  if (value < 0) return 0;
  if (value > 255) return 255;
  return value;
}
