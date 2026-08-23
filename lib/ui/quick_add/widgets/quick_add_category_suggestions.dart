import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/common/widgets/category_tile.dart';
import 'package:mybudget/ui/common/widgets/section_header.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';

/// The categories the model hesitated between, laid out where the breakdown
/// normally sits : while a draft is being typed, correcting it matters more
/// than reading the month.
class QuickAddCategorySuggestions extends StatelessWidget {
  final List<CategoryDisplay> suggestions;
  final String selectedSlug;
  final ValueChanged<String> onSelected;
  final VoidCallback onBrowseAll;

  const QuickAddCategorySuggestions({
    required this.suggestions,
    required this.selectedSlug,
    required this.onSelected,
    required this.onBrowseAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Catégorie',
          trailing: 'Tap pour corriger',
        ),
        SolidCard(
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedSpacing.sp2,
            vertical: FrostedSpacing.sp1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final category in suggestions)
                CategoryTile(
                  category: category,
                  subtitle: category.groupLabel,
                  selected: category.slug == selectedSlug,
                  onTap: () => onSelected(category.slug),
                ),
              FrostedListTile(
                leading: Icon(
                  Symbols.search_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: 'Toutes les catégories',
                variant: FrostedListTileVariant.plain,
                onTap: onBrowseAll,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
