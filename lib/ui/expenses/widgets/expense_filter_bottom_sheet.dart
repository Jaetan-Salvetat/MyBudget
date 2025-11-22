import 'package:flutter/material.dart';
import 'package:mybudget/models/expense_filter_data.dart';

class ExpenseFilterBottomSheet extends StatelessWidget {
  final ExpenseFilterData initialFilterData;
  final Function(ExpenseFilterData) onApply;
  final VoidCallback onClear;
  final VoidCallback onCancel;

  const ExpenseFilterBottomSheet({
    required this.initialFilterData,
    required this.onApply,
    required this.onClear,
    required this.onCancel,
    super.key,
  });

  static void show({
    required BuildContext context,
    required ExpenseFilterData initialFilterData,
    required Function(ExpenseFilterData) onApply,
    required VoidCallback onClear,
    required VoidCallback onCancel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ExpenseFilterBottomSheet(
            initialFilterData: initialFilterData,
            onApply: onApply,
            onClear: onClear,
            onCancel: onCancel,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
     
     
     

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filtrer les dépenses',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
           
          const Text(
            'Filtres non implémentés dans cette version de migration rapide.',
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  onClear();
                  Navigator.pop(context);
                },
                child: const Text('Effacer'),
              ),
              TextButton(
                onPressed: () {
                  onCancel();
                  Navigator.pop(context);
                },
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                   
                  onApply(initialFilterData);
                  Navigator.pop(context);
                },
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
