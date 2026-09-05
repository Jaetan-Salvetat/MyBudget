import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/models/quick_add_draft_model.dart';
import 'package:mybudget/ui/common/widgets/category_picker_sheet.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_draft_line.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_frequency_menu.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

class QuickAddPreview extends ConsumerWidget {
  const QuickAddPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(quickAddProvider);
    if (draft.isEmpty) return const SizedBox.shrink();

    final error = draft.analysisError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuickAddDraftLine(
          amount: draft.amount,
          isIncome: draft.type == TransactionType.income,
          category: _category(context, ref, draft),
          recurrenceLabel: draft.frequency.label,
          dateLabel: _dateLabel(draft),
          isStale: draft.isStale,
          onPickCategory: () => _pickCategory(context, ref, draft),
          onPickDate: () => _pickDate(context, ref, draft),
          onPickFrequency: () => _pickFrequency(context, ref, draft),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: FrostedSpacing.sp2),
            child: _AnalysisError(message: error),
          ),
      ],
    );
  }

  String? _dateLabel(QuickAddDraft draft) {
    final date = draft.date;
    if (date == null) return null;

    if (draft.frequency == Frequency.oneTime) {
      final today = DateUtils.dateOnly(DateTime.now());
      final days = today.difference(DateUtils.dateOnly(date)).inDays;
      if (days == 0) return 'Aujourd\'hui';
      if (days == 1) return 'Hier';
    }

    return DateSelector.labelFor(draft.frequency, date);
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    QuickAddDraft draft,
  ) async {
    final picked = await DateSelector.showFor(
      context: context,
      frequency: draft.frequency,
      initialDate: draft.date ?? DateTime.now(),
    );
    if (picked == null) return;
    ref.read(quickAddProvider.notifier).selectDate(picked);
  }

  void _pickFrequency(
    BuildContext context,
    WidgetRef ref,
    QuickAddDraft draft,
  ) {
    QuickAddFrequencyMenu.show(
      context: context,
      current: draft.frequency,
      onSelect: ref.read(quickAddProvider.notifier).selectFrequency,
    );
  }

  QuickAddCategoryPreview? _category(
    BuildContext context,
    WidgetRef ref,
    QuickAddDraft draft,
  ) {
    final slug = draft.categorySlug;
    if (slug == null && draft.isStale) return null;

    final isNamed = slug != null;
    final CategoryDisplay? display = ref
        .watch(categoryDisplayResolverProvider)
        .value
        ?.resolve(draft.categorySlugOrFallback);
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
      isUncertain: !isNamed || draft.isCategoryUncertain,
    );
  }

  Future<void> _pickCategory(
    BuildContext context,
    WidgetRef ref,
    QuickAddDraft draft,
  ) async {
    final slug = await CategoryPickerSheet.show(
      context,
      type: null,
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
