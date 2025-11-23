import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/core/repositories/category_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/models/category_model.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late CategoryViewModel viewModel;
  late MockCategoryRepository mockCategoryRepository;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'isFirstLaunch': false});
    await PreferencesService.init();
    mockCategoryRepository = MockCategoryRepository();

    // Default behavior
    when(() => mockCategoryRepository.getAll()).thenReturn([]);

    viewModel = CategoryViewModel(mockCategoryRepository);
  });

  group('CategoryViewModel', () {
    test('initial load should fetch categories', () async {
      // Wait for async init in constructor if any (it's fire-and-forget in constructor,
      // but we can verify repository calls)
      // Since _loadCategories is async but called in constructor, we might need to wait a bit
      // or rely on the fact that getAll is called synchronously after await initDefaultCategories (if first launch).

      // Actually, _loadCategories is async. Constructor doesn't await it.
      // We can't easily await the constructor's async work.
      // However, we can verify interaction eventually.

      await Future.delayed(Duration.zero); // Let event loop run

      verify(() => mockCategoryRepository.getAll()).called(1);
    });

    test('addCategory should call repository and reload', () async {
      final category = CategoryModel.create(name: 'New', icon: 'icon');

      when(() => mockCategoryRepository.add(category)).thenReturn(1);
      when(() => mockCategoryRepository.getAll()).thenReturn([category]);

      await viewModel.addCategory(category);

      verify(() => mockCategoryRepository.add(category)).called(1);
      // Called once in init (maybe) and once in addCategory
      verify(() => mockCategoryRepository.getAll()).called(greaterThan(1));
      expect(viewModel.categories.length, 1);
    });

    test('deleteCategory should call repository and reload', () async {
      when(() => mockCategoryRepository.delete(1)).thenReturn(true);

      await viewModel.deleteCategory(1);

      verify(() => mockCategoryRepository.delete(1)).called(1);
    });
  });
}
