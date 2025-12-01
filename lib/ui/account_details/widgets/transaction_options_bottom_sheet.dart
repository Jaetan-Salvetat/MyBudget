import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

class TransactionOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onDelete;

  const TransactionOptionsBottomSheet({required this.onDelete, super.key});

  static void show(BuildContext context, {required VoidCallback onDelete}) {
    FrostedBottomSheet.show(
      context: context,
      child: TransactionOptionsBottomSheet(onDelete: onDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Options', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FrostedTextButton(
              onPressed: () {
                onDelete();
                Navigator.pop(context);
              },
              child: Text(
                'Supprimer',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
