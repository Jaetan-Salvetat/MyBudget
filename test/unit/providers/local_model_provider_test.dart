import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/local_model_status.dart';
import 'package:mybudget/ui/settings/local_model_provider.dart';

void main() {
  group('LocalModelState', () {
    test('default values', () {
      const state = LocalModelState();

      expect(state.status, LocalModelStatus.none);
      expect(state.downloadProgress, 0.0);
      expect(state.error, isNull);
      expect(state.availableSpaceGb, isNull);
      expect(state.modelPath, isNull);
    });

    test('copyWith replaces specified fields', () {
      const state = LocalModelState();
      final updated = state.copyWith(
        status: LocalModelStatus.downloading,
        downloadProgress: 0.5,
      );

      expect(updated.status, LocalModelStatus.downloading);
      expect(updated.downloadProgress, 0.5);
      expect(updated.error, isNull);
      expect(updated.modelPath, isNull);
    });

    test('copyWith preserves unspecified fields', () {
      const state = LocalModelState(
        status: LocalModelStatus.ready,
        modelPath: '/path/to/model',
        downloadProgress: 1.0,
        error: 'some error',
        availableSpaceGb: 10.0,
      );
      final updated = state.copyWith(downloadProgress: 0.8);

      expect(updated.status, LocalModelStatus.ready);
      expect(updated.modelPath, '/path/to/model');
      expect(updated.downloadProgress, 0.8);
      expect(updated.error, 'some error');
      expect(updated.availableSpaceGb, 10.0);
    });

    test('clearError removes error but keeps other fields', () {
      const state = LocalModelState(
        status: LocalModelStatus.downloading,
        downloadProgress: 0.3,
        error: 'Erreur réseau',
        modelPath: '/path',
        availableSpaceGb: 5.0,
      );
      final cleared = state.clearError();

      expect(cleared.error, isNull);
      expect(cleared.status, LocalModelStatus.downloading);
      expect(cleared.downloadProgress, 0.3);
      expect(cleared.modelPath, '/path');
      expect(cleared.availableSpaceGb, 5.0);
    });

    test('copyWith then clearError chains correctly', () {
      const state = LocalModelState();
      final result = state
          .copyWith(
            status: LocalModelStatus.downloading,
            error: 'test',
          )
          .clearError();

      expect(result.status, LocalModelStatus.downloading);
      expect(result.error, isNull);
    });

    test('copyWith with all fields', () {
      const state = LocalModelState();
      final updated = state.copyWith(
        status: LocalModelStatus.ready,
        downloadProgress: 1.0,
        error: 'done',
        availableSpaceGb: 8.5,
        modelPath: '/data/model.litertlm',
      );

      expect(updated.status, LocalModelStatus.ready);
      expect(updated.downloadProgress, 1.0);
      expect(updated.error, 'done');
      expect(updated.availableSpaceGb, 8.5);
      expect(updated.modelPath, '/data/model.litertlm');
    });
  });
}
