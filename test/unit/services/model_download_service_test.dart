import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/local_model_catalog.dart';
import 'package:mybudget/core/services/model_download_service.dart';

void main() {
  group('LocalModelCatalog', () {
    test('all models have valid URLs pointing to HuggingFace', () {
      for (final config in LocalModelCatalog.models) {
        expect(config.url, contains('huggingface.co'));
      }
    });

    test('all models have non-empty filenames', () {
      for (final config in LocalModelCatalog.models) {
        expect(config.filename, isNotEmpty);
        expect(config.filename, endsWith('.litertlm'));
      }
    });

    test('requiredSpaceGb is greater than sizeGb for all models', () {
      for (final config in LocalModelCatalog.models) {
        expect(
          config.requiredSpaceGb,
          greaterThan(config.sizeGb),
        );
      }
    });

    test('all models have unique IDs', () {
      final ids = LocalModelCatalog.models.map((c) => c.id).toSet();
      expect(ids.length, LocalModelCatalog.models.length);
    });

    test('all models have unique taskGroups', () {
      final groups = LocalModelCatalog.models.map((c) => c.taskGroup).toSet();
      expect(groups.length, LocalModelCatalog.models.length);
    });

    test('getById returns correct model', () {
      final config = LocalModelCatalog.getById('gemma-4-e2b');
      expect(config, isNotNull);
      expect(config!.displayName, 'Gemma 4 E2B');
    });

    test('getById returns null for unknown id', () {
      expect(LocalModelCatalog.getById('unknown'), isNull);
    });

    test('catalog contains 3 models', () {
      expect(LocalModelCatalog.models.length, 3);
    });
  });

  group('ModelDownloadException', () {
    test('stores message', () {
      const exception = ModelDownloadException('test error');
      expect(exception.message, 'test error');
    });

    test('toString returns message', () {
      const exception = ModelDownloadException('download failed');
      expect(exception.toString(), 'download failed');
    });
  });
}
