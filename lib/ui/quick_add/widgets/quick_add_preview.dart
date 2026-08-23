import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/models/quick_add_draft_model.dart';
import 'package:mybudget/ui/common/widgets/category_picker_sheet.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_preview_chips.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

/// Turns the live draft into the chips the user reads while typing.
class QuickAddPreview extends ConsumerWidget {
  const QuickAddPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(quickAddProvider);
    if (draft.isEmpty) return const SizedBox.shrink();

    final error = draft.analysisError;
    if (error != null) return _AnalysisError(message: error);

    return QuickAddPreviewChips(
      amountLabel: _amountLabel(draft),
      category: _category(context, ref, draft),
      recurrenceLabel: draft.frequency == Frequency.oneTime
          ? null
          : draft.frequency.label,
      isAnalyzing: draft.isAnalyzing,
      onPickCategory: () => _pickCategory(context, ref, draft),
    );
  }

  String? _amountLabel(QuickAddDraft draft) {
    final amount = draft.amount;
    if (amount == null) return null;

    final formatted = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
    ).format(amount);
    return draft.type == TransactionType.income ? '+ $formatted' : formatted;
  }

  QuickAddCategoryPreview? _category(
    BuildContext context,
    WidgetRef ref,
    QuickAddDraft draft,
  ) {
    final slug = draft.categorySlug;
    if (slug == null) return null;

    final CategoryDisplay? display = ref
        .watch(categoryDisplayResolverProvider)
        .value
        ?.resolve(slug);
    if (display == null) {
      return QuickAddCategoryPreview(
        label: 'Choisir une catégorie',
        icon: Symbols.category_rounded,
        color: Theme.of(context).colorScheme.primary,
        isUncertain: true,
      );
    }

    return QuickAddCategoryPreview(
      label: display.label,
      icon: CategoryDefaults.resolveIcon(display.icon),
      color: Color(display.color),
      isUncertain: draft.isCategoryUncertain,
    );
  }

  Future<void> _pickCategory(
    BuildContext context,
    WidgetRef ref,
    QuickAddDraft draft,
  ) async {
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

class _AnalysisError extends StatelessWidget {
  final String message;

  const _AnalysisError({required this.message});

  @override
  Widget build(BuildContext context) {
    final color = context.financeColors.expense;
    return Row(
      children: [
        Icon(Symbols.error_rounded, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
