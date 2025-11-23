import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/settings/widgets/categories_bottom_sheet.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/models/category_model.dart';

class MockCategoryViewModel extends Mock implements CategoryViewModel {}

void main() {
  late MockCategoryViewModel mockCategoryViewModel;

  setUpAll(() {
    registerFallbackValue(CategoryModel.create(name: 'Fallback', icon: 'icon'));
  });

  setUp(() {
    mockCategoryViewModel = MockCategoryViewModel();
    when(() => mockCategoryViewModel.categories).thenReturn([]);
    when(() => mockCategoryViewModel.isLoading).thenReturn(false);
    when(
      () => mockCategoryViewModel.addCategory(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockCategoryViewModel.updateCategory(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockCategoryViewModel.deleteCategory(any()),
    ).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<CategoryViewModel>.value(
      value: mockCategoryViewModel,
      child: const MaterialApp(home: Scaffold(body: CategoriesBottomSheet())),
    );
  }

  group('CategoriesBottomSheet', () {
    testWidgets('renders add button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Ajouter une catégorie'), findsOneWidget);
    });

    testWidgets('shows add dialog on tap', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Ajouter une catégorie'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Nouvelle catégorie'), findsOneWidget);
      expect(find.text('Nom'), findsOneWidget);
    });

    testWidgets('adds category via dialog', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Ajouter une catégorie'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(seconds: 1)); // Wait for animation

      expect(find.text('Nouvelle catégorie'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'New Category');
      await tester.pump();

      // Find the 'Ajouter' button specifically in the dialog actions
      final addButton = find.descendant(
        of: find.byType(FrostedFilledButton),
        matching: find.text('Ajouter'),
      );

      await tester.tap(addButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // Wait for close animation

      verify(() => mockCategoryViewModel.addCategory(any())).called(1);
    });
  });
}
