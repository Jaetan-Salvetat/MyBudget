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

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(amount);
  }

  String _categoryLabel() {
    if (widget.result.newCategory != null) {
      return 'Nouvelle : ${widget.result.newCategory}';
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
    if (widget.result.newCategory != null && widget.result.newCategoryColor != null) {
      final color = CategoryDefaults.hexToColor(widget.result.newCategoryColor!);
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
      ref
          .read(quickAddProvider.notifier)
          .confirmExpense(_selectedAccountId!);
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.md,
        vertical: FrostedSpacing.xs,
      ),
      child: FrostedCard(
        padding: const EdgeInsets.all(FrostedSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_categoryIcon(), size: 20, color: catColor),
                const SizedBox(width: FrostedSpacing.sm),
                Expanded(
                  child: Text(
                    _categoryLabel(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: catColor,
                        ),
                  ),
                ),
                Text(
                  _formatAmount(widget.result.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: FrostedSpacing.xxs),
                GestureDetector(
                  onTap: () =>
                      ref.read(quickAddProvider.notifier).reset(),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: FrostedSpacing.xxs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.result.name} · ${widget.result.frequency}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
