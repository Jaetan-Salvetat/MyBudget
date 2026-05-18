import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';

import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_result_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/settings/category_provider.dart';

class QuickAddConfirmationCard extends ConsumerStatefulWidget {
  final QuickAddResultModel result;

  const QuickAddConfirmationCard({required this.result, super.key});

  @override
  ConsumerState<QuickAddConfirmationCard> createState() =>
      _QuickAddConfirmationCardState();
}

class _QuickAddConfirmationCardState
    extends ConsumerState<QuickAddConfirmationCard> {
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final accounts = ref.read(accountProvider).value ?? [];
    if (accounts.length == 1) {
      _selectedAccountId = accounts.first.id;
    }
  }

  String _categoryLabel() {
    if (widget.result.newCategory != null) {
      return widget.result.newCategory!;
    }
    final categories = ref.read(categoryProvider).value ?? [];
    final cat = categories.where((c) => c.id == widget.result.categoryId);
    return cat.isNotEmpty ? cat.first.name : 'Catégorie inconnue';
  }

  IconData _categoryIcon() {
    if (widget.result.newCategory != null) {
      return CategoryDefaults.resolveIcon(
        widget.result.newCategoryIcon ?? CategoryDefaults.defaultIcon,
      );
    }
    final categories = ref.read(categoryProvider).value ?? [];
    final cat = categories.where((c) => c.id == widget.result.categoryId);
    return cat.isNotEmpty ? cat.first.getIconData() : Icons.category;
  }

  Color _categoryColor() {
    if (widget.result.newCategory != null &&
        widget.result.newCategoryColor != null) {
      final color =
          CategoryDefaults.hexToColor(widget.result.newCategoryColor!);
      if (color != null) return Color(color);
    }
    if (widget.result.categoryId != null) {
      final categories = ref.read(categoryProvider).value ?? [];
      final cat = categories.where((c) => c.id == widget.result.categoryId);
      if (cat.isNotEmpty) return Color(cat.first.color);
    }
    return Theme.of(context).colorScheme.primary;
  }

  void _openFullForm() {
    final accounts = ref.read(accountProvider).value ?? [];
    final categories = ref.read(categoryProvider).value ?? [];
    final ctx = context;

    ExpenseBottomSheet.show(
      context: ctx,
      accounts: accounts,
      categories: categories,
      closedExpenses: ref.read(expenseProvider.notifier).getClosedExpenses(),
      expense: ExpenseModel.create(
        name: widget.result.name,
        amount: widget.result.amount,
        categoryId: widget.result.categoryId ?? 0,
        startDate: DateTime.now(),
        frequency: widget.result.frequency,
        accountId: _selectedAccountId ?? accounts.first.id,
      ),
      onSubmit: (expense) async {
        try {
          await ref.read(expenseProvider.notifier).addExpense(expense);
          ref.read(quickAddProvider.notifier).reset();
        } catch (e) {
          if (ctx.mounted) {
            FrostedSnackbar.show(ctx, message: 'Erreur lors de l\'ajout: $e');
          }
        }
      },
      onCancel: () {},
    );
  }

  void _confirm() {
    if (_selectedAccountId == null) return;

    try {
      ref.read(quickAddProvider.notifier).confirmExpense(_selectedAccountId!);
    } catch (e) {
      if (context.mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de l\'ajout: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider).value ?? [];
    final colorScheme = Theme.of(context).colorScheme;
    final catColor = _categoryColor();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FrostedSpacing.xl,
        FrostedSpacing.sm,
        FrostedSpacing.xl,
        0,
      ),
      child: FrostedCard(
        padding: const EdgeInsets.all(FrostedSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_categoryIcon(), size: 18, color: catColor),
                ),
                const SizedBox(width: FrostedSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.result.name,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _categoryLabel(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: catColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (widget.result.newCategory != null) ...[
                            const SizedBox(width: FrostedSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'nouvelle',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: catColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatter.format(widget.result.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.result.frequency,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: FrostedSpacing.xxs),
                GestureDetector(
                  onTap: () => ref.read(quickAddProvider.notifier).reset(),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (accounts.length > 1) ...[
              const SizedBox(height: FrostedSpacing.sm),
              FrostedDropdown<int>(
                value: _selectedAccountId,
                hint: 'Compte',
                items: accounts
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      ),
                    )
                    .toList(),
                onChanged: (id) => setState(() => _selectedAccountId = id),
              ),
            ],
            const SizedBox(height: FrostedSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FrostedTextButton(
                  onPressed: _openFullForm,
                  child: const Text('Modifier'),
                ),
                const SizedBox(width: FrostedSpacing.sm),
                FrostedFilledButton(
                  onPressed: _selectedAccountId != null ? _confirm : null,
                  child: const Text('Confirmer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
