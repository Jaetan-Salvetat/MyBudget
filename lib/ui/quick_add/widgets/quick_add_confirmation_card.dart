import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';

import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_result_model.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/widgets/category_icon.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/expenses/widgets/expense_bottom_sheet.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_bottom_sheet.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/ui/common/widgets/category_picker_sheet.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

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
    if (accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }
  }

  bool get _isIncome => widget.result.type == TransactionType.income;

  CategoryDisplay? get _category {
    final slug = widget.result.categorySlug;
    if (slug == null) return null;
    return ref.watch(categoryDisplayResolverProvider).value?.resolve(slug);
  }

  String _categoryLabel() {
    if (_isIncome) return 'Revenu';
    final category = _category;
    if (category == null) return 'Choisir une catégorie';
    return '${category.groupLabel} · ${category.label}';
  }

  IconData _categoryIcon() {
    if (_isIncome) return Symbols.paid_rounded;
    final category = _category;
    return category == null
        ? Symbols.category_rounded
        : CategoryDefaults.resolveIcon(category.icon);
  }

  Color _categoryColor() {
    if (_isIncome) return context.financeColors.income;
    final category = _category;
    return category == null
        ? Theme.of(context).colorScheme.primary
        : Color(category.color);
  }

  Future<void> _pickCategory() async {
    final slug = await CategoryPickerSheet.show(
      context,
      selectedSlug: widget.result.categorySlug,
      suggestions: widget.result.categorySuggestions,
    );
    if (slug == null) return;
    ref.read(quickAddProvider.notifier).selectCategory(slug);
  }

  void _openFullForm() {
    final accounts = ref.read(accountProvider).value ?? [];
    final ctx = context;

    if (_isIncome) {
      RevenueBottomSheet.show(
        context: ctx,
        accounts: accounts,
        closedRevenues: ref.read(revenueProvider.notifier).getClosedRevenues(),
        revenue: RevenueModel.create(
          name: widget.result.name,
          amount: widget.result.amount,
          startDate: DateTime.now(),
          frequency: widget.result.frequency,
          accountId: _selectedAccountId ?? accounts.first.id,
        ),
        onSubmit: (revenue) async {
          try {
            await ref.read(revenueProvider.notifier).addRevenue(revenue);
            ref.read(quickAddProvider.notifier).reset();
          } catch (e) {
            if (ctx.mounted) {
              FrostedSnackbar.show(ctx, message: 'Erreur lors de l\'ajout: $e');
            }
          }
        },
        onCancel: () {},
      );
      return;
    }

    ExpenseBottomSheet.show(
      context: ctx,
      accounts: accounts,
      closedExpenses: ref.read(expenseProvider.notifier).getClosedExpenses(),
      expense: ExpenseModel.create(
        name: widget.result.name,
        amount: widget.result.amount,
        categorySlug: widget.result.categorySlug,
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

  Future<void> _confirm() async {
    final accountId = _selectedAccountId;
    if (accountId == null) return;

    try {
      await ref.read(quickAddProvider.notifier).confirm(accountId);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(context, message: 'Erreur lors de l\'ajout: $e');
      }
    }
  }

  String _frequencyLabel() {
    final freq = widget.result.frequency;
    if (freq == 'Mensuel') return 'Mensuel · Récurrent détecté';
    if (freq == 'Annuel') return 'Annuel · Récurrent détecté';
    return 'Ponctuel';
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider).value ?? [];
    final scheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final catColor = _categoryColor();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return FrostedGlass(
      padding: const EdgeInsets.all(FrostedSpacing.sp4),
      borderRadius: BorderRadius.circular(FrostedRadius.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Symbols.auto_awesome_rounded,
                size: 16,
                color: scheme.primary,
                fill: 1,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Eyebrow(
                  _isIncome ? '1 revenu détecté' : '1 dépense détectée',
                  color: scheme.primary,
                ),
              ),
              Text(
                'Total ',
                style: TextStyle(
                  fontSize: 12,
                  height: 14 / 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatter.format(widget.result.amount),
                style: AppTextStyles.amount(
                  fontSize: 12,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ref.read(quickAddProvider.notifier).reset(),
                child: Icon(
                  Symbols.close_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ParsedRow(
            name: widget.result.name,
            categoryLabel: _categoryLabel(),
            frequencyLabel: _frequencyLabel(),
            icon: _categoryIcon(),
            color: catColor,
            amount: widget.result.amount,
            amountColor: _isIncome ? finance.income : finance.expense,
            amountSign: _isIncome ? '+' : '−',
            needsConfirmation: widget.result.needsCategoryConfirmation,
            onCategoryTap: _isIncome ? null : _pickCategory,
          ),
          const SizedBox(height: 12),
          if (accounts.isNotEmpty)
            _AccountSelector(
              accounts: accounts,
              selectedId: _selectedAccountId,
              onChanged: (id) => setState(() => _selectedAccountId = id),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FrostedButton.outlined(
                  label: 'Modifier',
                  icon: Symbols.edit_rounded,
                  onPressed: _openFullForm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FrostedButton.filled(
                  label: 'Confirmer',
                  icon: Symbols.check_rounded,
                  onPressed: _selectedAccountId != null ? _confirm : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParsedRow extends StatelessWidget {
  final String name;
  final String categoryLabel;
  final String frequencyLabel;
  final IconData icon;
  final Color color;
  final double amount;
  final Color amountColor;
  final String amountSign;
  final bool needsConfirmation;
  final VoidCallback? onCategoryTap;

  const _ParsedRow({
    required this.name,
    required this.categoryLabel,
    required this.frequencyLabel,
    required this.icon,
    required this.color,
    required this.amount,
    required this.amountColor,
    required this.amountSign,
    required this.needsConfirmation,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Row(
      children: [
        GestureDetector(
          onTap: onCategoryTap,
          child: CategoryIcon(
            icon: icon,
            color: color,
            size: CategoryIconSize.sm,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: onCategoryTap,
                      child: Text(
                        '$categoryLabel · $frequencyLabel',
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (needsConfirmation) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'à confirmer',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$amountSign ${formatter.format(amount).replaceAll('−', '').replaceAll('+', '')}',
          style: AppTextStyles.amount(fontSize: 16, color: amountColor),
        ),
      ],
    );
  }
}

class _AccountSelector extends StatelessWidget {
  final List<AccountModel> accounts;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  const _AccountSelector({
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final current = accounts.firstWhere(
      (a) => a.id == selectedId,
      orElse: () => accounts.first,
    );

    return InkWell(
      onTap: accounts.length > 1 ? () => _showPicker(context) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Symbols.account_balance_wallet_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: 'Vers '),
                    TextSpan(
                      text: current.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (accounts.length > 1)
              Icon(
                Symbols.expand_more_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: 'Vers quel compte ?',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: accounts
              .map(
                (a) => FrostedListTile(
                  title: a.name,
                  subtitle: a.bank,
                  leading: const Icon(Symbols.account_balance_wallet_rounded),
                  trailing: a.id == selectedId
                      ? Icon(
                          Symbols.check_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    onChanged(a.id);
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
