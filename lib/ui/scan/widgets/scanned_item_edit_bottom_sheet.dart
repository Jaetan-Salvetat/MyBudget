import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';

class ScannedItemEditBottomSheet extends StatefulWidget {
  final ScannedItemModel item;
  final List<CategoryModel> categories;
  final void Function(int categoryId, String categoryName) onCategoryChanged;
  final void Function(double amount) onAmountChanged;
  final VoidCallback onDelete;

  const ScannedItemEditBottomSheet({
    required this.item,
    required this.categories,
    required this.onCategoryChanged,
    required this.onAmountChanged,
    required this.onDelete,
    super.key,
  });

  static void show({
    required BuildContext context,
    required ScannedItemModel item,
    required List<CategoryModel> categories,
    required void Function(int categoryId, String categoryName) onCategoryChanged,
    required void Function(double amount) onAmountChanged,
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
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.item.amount.toStringAsFixed(2),
    );
    _selectedCategoryId = widget.item.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
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
            prefixIcon: const Icon(Icons.euro),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _handleAmountChanged(),
          ),
          const SizedBox(height: 16),
          FrostedDropdown<int>(
            value: _selectedCategoryId,
            items: widget.categories.map((category) {
              return DropdownMenuItem<int>(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategoryId = value);
                final category = widget.categories.firstWhere(
                  (c) => c.id == value,
                );
                widget.onCategoryChanged(value, category.name);
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
                  Icon(Icons.delete_outline, color: theme.colorScheme.error),
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
}
