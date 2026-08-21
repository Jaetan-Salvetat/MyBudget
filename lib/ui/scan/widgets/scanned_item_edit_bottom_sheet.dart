import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/scanned_item_model.dart';

class ScannedItemEditBottomSheet extends StatefulWidget {
  final ScannedItemModel item;
  final List<CategoryDisplay> categories;
  final void Function(String categorySlug, String categoryName)
      onCategoryChanged;
  final void Function(double amount) onAmountChanged;
  final void Function(double discount) onDiscountChanged;
  final VoidCallback onDelete;

  const ScannedItemEditBottomSheet({
    required this.item,
    required this.categories,
    required this.onCategoryChanged,
    required this.onAmountChanged,
    required this.onDiscountChanged,
    required this.onDelete,
    super.key,
  });

  static void show({
    required BuildContext context,
    required ScannedItemModel item,
    required List<CategoryDisplay> categories,
    required void Function(String categorySlug, String categoryName)
        onCategoryChanged,
    required void Function(double amount) onAmountChanged,
    required void Function(double discount) onDiscountChanged,
    required VoidCallback onDelete,
  }) {
    FrostedBottomSheet.show(
      context: context,
      title: 'Modifier l\'article',
      child: ScannedItemEditBottomSheet(
        item: item,
        categories: categories,
        onCategoryChanged: onCategoryChanged,
        onAmountChanged: onAmountChanged,
        onDiscountChanged: onDiscountChanged,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<ScannedItemEditBottomSheet> createState() =>
      _ScannedItemEditBottomSheetState();
}

class _ScannedItemEditBottomSheetState
    extends State<ScannedItemEditBottomSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _discountController;
  String? _selectedCategorySlug;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.item.amount.toStringAsFixed(2),
    );
    _discountController = TextEditingController(
      text: widget.item.discount.toStringAsFixed(2),
    );
    _selectedCategorySlug = widget.item.categorySlug;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          FrostedTextField(
            controller: _amountController,
            labelText: 'Montant (€)',
            prefixIcon: const Icon(Symbols.euro_rounded),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _handleAmountChanged(),
          ),
          const SizedBox(height: 8),
          FrostedTextField(
            controller: _discountController,
            labelText: 'Remise (€)',
            prefixIcon: const Icon(Symbols.sell_rounded),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _handleDiscountChanged(),
          ),
          const SizedBox(height: 16),
          FrostedDropdown<String>(
            value: _selectedCategorySlug,
            items: widget.categories.map((category) {
              return DropdownMenuItem<String>(
                value: category.slug,
                child: Text('${category.groupLabel} · ${category.label}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategorySlug = value);
                final category = widget.categories.firstWhere(
                  (c) => c.slug == value,
                );
                widget.onCategoryChanged(value, category.label);
              }
            },
            hint: 'Catégorie',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FrostedTextButton(
              onPressed: () {
                widget.onDelete();
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.delete_rounded, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'Supprimer cet article',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAmountChanged() {
    final parsed = double.tryParse(_amountController.text);
    if (parsed != null && parsed >= 0) {
      widget.onAmountChanged(parsed);
    }
  }

  void _handleDiscountChanged() {
    final parsed = double.tryParse(_discountController.text);
    if (parsed != null && parsed >= 0) {
      widget.onDiscountChanged(parsed);
    }
  }
}
