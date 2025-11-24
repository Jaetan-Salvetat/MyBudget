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

    when(() => mockCategoryRepository.getAll()).thenReturn([]);

    viewModel = CategoryViewModel(mockCategoryRepository);
  });

  group('CategoryViewModel', () {
    test('initial load should fetch categories', () async {
      await Future.delayed(Duration.zero);

      verify(() => mockCategoryRepository.getAll()).called(1);
    });

    test('addCategory should call repository and reload', () async {
      final category = CategoryModel.create(name: 'New', icon: 'icon');

      when(() => mockCategoryRepository.add(category)).thenReturn(1);
      when(() => mockCategoryRepository.getAll()).thenReturn([category]);

      await viewModel.addCategory(category);

      verify(() => mockCategoryRepository.add(category)).called(1);
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
