import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/category_override_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_override_provider.g.dart';

@Riverpod(keepAlive: true)
class CategoryOverrideNotifier extends _$CategoryOverrideNotifier {
  @override
  Future<Map<String, CategoryOverrideModel>> build() async {
    return ref.watch(categoryOverrideRepositoryProvider).getAll();
  }

  Future<void> customize(
    String slug, {
    String? name,
    String? icon,
    int? color,
  }) async {
    final repo = ref.read(categoryOverrideRepositoryProvider);
    final existing = repo.get(slug);
    repo.save(
      existing?.copyWith(name: name, icon: icon, color: color) ??
          CategoryOverrideModel.create(
            slug: slug,
            name: name,
            icon: icon,
            color: color,
          ),
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> reset(String slug) async {
    ref.read(categoryOverrideRepositoryProvider).delete(slug);
    ref.invalidateSelf();
    await future;
  }
}

@Riverpod(keepAlive: true)
Future<CategoryDisplayResolver> categoryDisplayResolver(Ref ref) async {
  return CategoryDisplayResolver(
    taxonomy: await ref.watch(categoryTaxonomyProvider.future),
    overrides: await ref.watch(categoryOverrideProvider.future),
  );
}
