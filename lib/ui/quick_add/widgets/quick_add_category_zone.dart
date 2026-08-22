import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/common/widgets/category_picker_sheet.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_category_suggestions.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

/// Holds one slot on the dashboard : the month's breakdown normally, the
/// model's candidates while a draft is waiting for a category it can trust.
class QuickAddCategoryZone extends ConsumerWidget {
  final bool typing;
  final Widget breakdown;

  const QuickAddCategoryZone({
    required this.typing,
    required this.breakdown,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!typing) return breakdown;

    final draft = ref.watch(quickAddProvider);
    final selectedSlug = draft.categorySlug;
    if (selectedSlug == null) return breakdown;

    final resolver = ref.watch(categoryDisplayResolverProvider).value;
    if (resolver == null) return breakdown;

    final suggestions = _candidates(resolver, draft.categorySuggestions, selectedSlug);
    if (suggestions.isEmpty) return breakdown;

    return QuickAddCategorySuggestions(
      suggestions: suggestions,
      selectedSlug: selectedSlug,
      onSelected: (slug) =>
          ref.read(quickAddProvider.notifier).selectCategory(slug),
      onBrowseAll: () => _browseAll(context, ref),
    );
  }

  /// The runners-up, with whatever the draft currently holds first : a category
  /// that came from the memory or from a manual pick is not in the model's list.
  List<CategoryDisplay> _candidates(
    CategoryDisplayResolver resolver,
    List<String> suggested,
    String selectedSlug,
  ) {
    final slugs = <String>[
      selectedSlug,
      ...suggested.where((slug) => slug != selectedSlug),
    ];
    return slugs.map(resolver.resolve).nonNulls.toList();
  }

  Future<void> _browseAll(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(quickAddProvider);
    final slug = await CategoryPickerSheet.show(
      context,
      type: draft.type,
      selectedSlug: draft.categorySlug,
      suggestions: draft.categorySuggestions,
    );
    if (slug == null) return;
    ref.read(quickAddProvider.notifier).selectCategory(slug);
  }
}
