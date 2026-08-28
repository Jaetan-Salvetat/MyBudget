import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/models/model_asset.dart';

void main() {
  final pattern = RegExp(r'^assets/models/model_v\d+\.onnx$');

  group('selectModelAsset', () {
    test('rend le seul asset qui correspond', () {
      final selected = selectModelAsset(
        const [
          'assets/images/logo.png',
          'assets/models/model_v5.onnx',
          'assets/models/tokenizer_v5.bin',
        ],
        pattern,
        'modèle quick-add',
      );

      expect(selected, 'assets/models/model_v5.onnx');
    });

    test('un asset manquant est dit tôt et clairement', () {
      expect(
        () => selectModelAsset(const [], pattern, 'modèle quick-add'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('modèle quick-add'),
              contains('./tool/models/fetch.sh'),
            ),
          ),
        ),
      );
    });

    test('deux versions côte à côte sont un refus, pas un choix', () {
      expect(
        () => selectModelAsset(
          const ['assets/models/model_v4.onnx', 'assets/models/model_v5.onnx'],
          pattern,
          'modèle quick-add',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Plusieurs'),
          ),
        ),
      );
    });
  });
}
