import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/local_model_status.dart';

void main() {
  group('LocalModelStatus', () {
    test('label returns correct French text for each status', () {
      expect(LocalModelStatus.none.label, 'Non installée');
      expect(LocalModelStatus.downloading.label, 'Téléchargement…');
      expect(LocalModelStatus.ready.label, 'Prête');
    });

    test('fromString returns matching status', () {
      expect(LocalModelStatus.fromString('none'), LocalModelStatus.none);
      expect(
        LocalModelStatus.fromString('downloading'),
        LocalModelStatus.downloading,
      );
      expect(LocalModelStatus.fromString('ready'), LocalModelStatus.ready);
    });

    test('fromString returns none for unknown value', () {
      expect(LocalModelStatus.fromString('unknown'), LocalModelStatus.none);
      expect(LocalModelStatus.fromString(''), LocalModelStatus.none);
    });
  });
}
