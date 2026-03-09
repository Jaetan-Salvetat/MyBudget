import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/settings/category_provider.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/models/category_model.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class FakeCategoryModel extends Fake implements CategoryModel {}

void main() {
  late MockCategoryRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeCategoryModel());
  });

  setUp(() async {
    mockRepository = MockCategoryRepository();
    when(() => mockRepository.getAll()).thenReturn([]);
    when(() => mockRepository.add(any())).thenReturn(1);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  }

  test('should initialize default categories on first launch', () async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    expect(PreferencesService.isCategoriesCreated(), false);

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(categoryProvider.future);
    await Future.delayed(const Duration(milliseconds: 500));

    verify(() => mockRepository.add(any())).called(greaterThan(5));

    expect(PreferencesService.isCategoriesCreated(), true);
  });

  test(
    'should NOT initialize default categories on subsequent launches',
    () async {
      SharedPreferences.setMockInitialValues({'isCategoriesCreated': true});
      await PreferencesService.init();

      expect(PreferencesService.isCategoriesCreated(), true);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(categoryProvider.future);
      await Future.delayed(const Duration(milliseconds: 500));

      verifyNever(() => mockRepository.add(any()));
    },
  );
}
