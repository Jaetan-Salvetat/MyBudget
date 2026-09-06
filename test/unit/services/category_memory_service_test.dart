import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/repositories/category_memory_repository.dart';
import 'package:mybudget/core/services/category_memory_service.dart';
import 'package:mybudget/models/category_memory_model.dart';

class MockCategoryMemoryRepository extends Mock
    implements CategoryMemoryRepository {}

class FakeCategoryMemoryModel extends Fake implements CategoryMemoryModel {}

void main() {
  late MockCategoryMemoryRepository repository;
  late CategoryMemoryService service;
  late Map<String, CategoryMemoryModel> store;

  final now = DateTime(2026, 8, 21);

  setUpAll(() => registerFallbackValue(FakeCategoryMemoryModel()));

  setUp(() {
    store = {};
    repository = MockCategoryMemoryRepository();
    service = CategoryMemoryService(repository, () => now);

    when(() => repository.get(any())).thenAnswer(
      (invocation) => store[invocation.positionalArguments.first as String],
    );
    when(() => repository.put(any())).thenAnswer((invocation) {
      final entry = invocation.positionalArguments.first as CategoryMemoryModel;
      store[entry.key] = entry;
    });
    when(() => repository.count()).thenAnswer((_) => store.length);
    when(() => repository.evictOldest(any())).thenAnswer((_) {});
    when(() => repository.delete(any())).thenAnswer((invocation) {
      store.remove(invocation.positionalArguments.first as String);
    });
  });

  group('normalizeKey', () {
    test('lowercases, strips accents and collapses whitespace', () {
      expect(CategoryMemoryService.normalizeKey('  MacDo  '), 'macdo');
      expect(CategoryMemoryService.normalizeKey('Café  Crème'), 'cafe creme');
      expect(CategoryMemoryService.normalizeKey('PÉAGE\tA7'), 'peage a7');
    });

    test('maps variants of the same text to one key', () {
      expect(
        CategoryMemoryService.normalizeKey('MACDO'),
        CategoryMemoryService.normalizeKey('macdo'),
      );
    });
  });

  group('recall', () {
    test('returns null when nothing was remembered', () {
      expect(service.recall('macdo'), isNull);
    });

    test('returns the remembered slug, whatever the casing', () {
      service.remember('macdo', 'restauration.fast_food');

      expect(service.recall('MacDo'), 'restauration.fast_food');
    });

    test('returns null for an empty key', () {
      expect(service.recall('   '), isNull);
    });

    test('does not match a longer text containing the key', () {
      service.remember('macdo', 'restauration.fast_food');

      expect(service.recall('macdo avec paul'), isNull);
    });

    test('returns null when the entry has memory disabled', () {
      service.remember('macdo', 'restauration.fast_food');
      store['macdo']!.useMemory = false;

      expect(service.recall('macdo'), isNull);
    });
  });

  group('remember', () {
    test('creates an entry on first pick', () {
      service.remember('macdo', 'restauration.fast_food');

      final entry = store['macdo']!;
      expect(entry.slug, 'restauration.fast_food');
      expect(entry.corrections, 1);
      expect(entry.useMemory, isTrue);
      expect(entry.updatedAt, now);
    });

    test('overwrites the slug and counts the edit', () {
      service.remember('macdo', 'restauration.fast_food');
      service.remember('macdo', 'loisirs.cinema_sortie');

      expect(store['macdo']!.slug, 'loisirs.cinema_sortie');
      expect(store['macdo']!.corrections, 2);
    });

    test('retires the entry on the fifth edit', () {
      service.remember('amazon', 'shopping.electronique');
      for (var i = 2; i < CategoryMemoryModel.freezeAfterCorrections; i++) {
        service.remember('amazon', 'shopping.vetements');
      }

      final entry = store['amazon']!;
      expect(entry.corrections, CategoryMemoryModel.freezeAfterCorrections - 1);
      expect(entry.isFrozen, isFalse);
      expect(entry.slug, 'shopping.vetements');

      expect(entry.useMemory, isTrue);

      service.remember('amazon', 'divers.autre');

      expect(entry.corrections, CategoryMemoryModel.freezeAfterCorrections);
      expect(entry.isFrozen, isTrue);
      expect(entry.useMemory, isFalse);
      expect(entry.slug, 'shopping.vetements');
      expect(service.recall('amazon'), isNull);

      service.remember('amazon', 'loisirs.livre_presse');

      expect(entry.slug, 'shopping.vetements');
      expect(entry.useMemory, isFalse);
      expect(entry.corrections, CategoryMemoryModel.freezeAfterCorrections + 1);
    });

    test('leaves useMemory on below the threshold', () {
      service.remember('macdo', 'restauration.fast_food');
      service.remember('macdo', 'loisirs.cinema_sortie');

      expect(store['macdo']!.useMemory, isTrue);
      expect(service.recall('macdo'), 'loisirs.cinema_sortie');
    });

    test('ignores an empty key', () {
      service.remember('   ', 'divers.autre');

      expect(store, isEmpty);
      verifyNever(() => repository.put(any()));
    });

    test('evicts the oldest entries when the cap is reached', () {
      when(
        () => repository.count(),
      ).thenReturn(CategoryMemoryService.maxEntries);

      service.remember('nouveau', 'divers.autre');

      verify(() => repository.evictOldest(1)).called(1);
    });

    test('does not evict below the cap', () {
      service.remember('macdo', 'restauration.fast_food');

      verifyNever(() => repository.evictOldest(any()));
    });
  });

  group('forget', () {
    test('removes the entry under its normalised key', () {
      service.remember('macdo', 'restauration.fast_food');

      service.forget('  MacDo ');

      expect(service.recall('macdo'), isNull);
    });
  });
}
