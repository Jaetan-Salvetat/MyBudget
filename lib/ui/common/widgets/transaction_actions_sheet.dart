import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

class TransactionActionsSheet {
  const TransactionActionsSheet._();

  static void show({
    required BuildContext context,
    required String deleteConfirmationMessage,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (sheetContext) => FrostedBottomSheet(
        title: 'Actions',
        child: FrostedListSection(
          tiles: [
            FrostedListTile(
              title: 'Modifier',
              leading: const Icon(Symbols.edit_rounded),
              onTap: () {
                Navigator.pop(sheetContext);
                onEdit();
              },
            ),
            FrostedListTile(
              title: 'Supprimer',
              leading: Icon(
                Symbols.delete_rounded,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(context, deleteConfirmationMessage, onDelete);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _confirmDelete(
    BuildContext context,
    String message,
    VoidCallback onDelete,
  ) {
    showFrostedDialog<void>(
      context: context,
      builder: (dialogContext) => FrostedDialog(
        title: 'Confirmer la suppression',
        body: Text(message),
        actions: [
          FrostedButton.text(
            label: 'Annuler',
            onPressed: () => Navigator.pop(dialogContext),
          ),
          FrostedButton.text(
            label: 'Supprimer',
            destructive: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}
