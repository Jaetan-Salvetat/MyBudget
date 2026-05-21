import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/services/model_download_service.dart';

void main() {
  group('ModelDownloadService', () {
    late ModelDownloadService service;

    setUp(() {
      service = ModelDownloadService();
    });

    group('constants', () {
      test('modelUrl points to HuggingFace', () {
        expect(ModelDownloadService.modelUrl, contains('huggingface.co'));
      });

      test('modelFilename matches expected file', () {
        expect(ModelDownloadService.modelFilename, 'gemma-4-E2B-it.litertlm');
      });

      test('requiredSpaceGb is greater than modelSizeGb', () {
        expect(
          ModelDownloadService.requiredSpaceGb,
          greaterThan(ModelDownloadService.modelSizeGb),
        );
      });

      test('taskGroup is non-empty', () {
        expect(ModelDownloadService.taskGroup, isNotEmpty);
      });
    });

    group('hasEnoughSpace', () {
      test('returns true when space exceeds requirement', () {
        expect(service.hasEnoughSpace(5.0), isTrue);
      });

      test('returns true when space equals requirement', () {
        expect(
          service.hasEnoughSpace(ModelDownloadService.requiredSpaceGb),
          isTrue,
        );
      });

      test('returns false when space is below requirement', () {
        expect(service.hasEnoughSpace(1.0), isFalse);
      });

      test('returns false when space is zero', () {
        expect(service.hasEnoughSpace(0.0), isFalse);
      });
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
