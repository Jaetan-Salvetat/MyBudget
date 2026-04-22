import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/services/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureStorageService', () {
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      SecureStorageService.storage = mockStorage;
    });

    test('getGeminiApiKey returns stored key', () async {
      when(() => mockStorage.read(key: 'gemini_api_key'))
          .thenAnswer((_) async => 'test-api-key');

      final result = await SecureStorageService.getGeminiApiKey();

      expect(result, 'test-api-key');
    });

    test('getGeminiApiKey returns null when no key stored', () async {
      when(() => mockStorage.read(key: 'gemini_api_key'))
          .thenAnswer((_) async => null);

      final result = await SecureStorageService.getGeminiApiKey();

      expect(result, null);
    });

    test('setGeminiApiKey writes key to storage', () async {
      when(() => mockStorage.write(key: 'gemini_api_key', value: 'my-key'))
          .thenAnswer((_) async {});

      await SecureStorageService.setGeminiApiKey('my-key');

      verify(() => mockStorage.write(key: 'gemini_api_key', value: 'my-key'))
          .called(1);
    });

    test('deleteGeminiApiKey removes key from storage', () async {
      when(() => mockStorage.delete(key: 'gemini_api_key'))
          .thenAnswer((_) async {});

      await SecureStorageService.deleteGeminiApiKey();

      verify(() => mockStorage.delete(key: 'gemini_api_key')).called(1);
    });

    test('hasGeminiApiKey returns true when key exists', () async {
      when(() => mockStorage.read(key: 'gemini_api_key'))
          .thenAnswer((_) async => 'some-key');

      final result = await SecureStorageService.hasGeminiApiKey();

      expect(result, true);
    });

    test('hasGeminiApiKey returns false when no key', () async {
      when(() => mockStorage.read(key: 'gemini_api_key'))
          .thenAnswer((_) async => null);

      final result = await SecureStorageService.hasGeminiApiKey();

      expect(result, false);
    });
  });
}
