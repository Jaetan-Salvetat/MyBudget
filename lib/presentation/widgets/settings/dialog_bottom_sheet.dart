import 'package:flutter/material.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';

class DialogBottomSheet {
  static Future<void> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    return AppModalBottomSheet.show(
      context: context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDestructive
                  ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.5)
                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDestructive ? Icons.warning_amber_rounded : Icons.info,
                      color: isDestructive
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppModalButton(
                label: cancelLabel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppModalButton(
                label: confirmLabel,
                isPrimary: true,
                isDestructive: isDestructive,
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
