import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/recurring_deletion.dart';

class TransactionActionsSheet {
  const TransactionActionsSheet._();

  static const String _scopeLabel = 'Retirer aussi le mois en cours';

  static const String _keepsTheMonth =
      'Le mois en cours garde son échéance, la règle s\'arrête après.';

  static const String _dropsTheMonth =
      'Le mois en cours perd son échéance, comme les suivants.';

  /// [initialScope] is null for a rule with no recurrence : there is then no
  /// month to argue about, and the dialog only confirms. Otherwise it is the
  /// answer offered already filled in, which the reader is free to change.
  static void show({
    required BuildContext context,
    required String deleteConfirmationMessage,
    required VoidCallback onEdit,
    required ValueChanged<RecurringDeletion> onDelete,
    RecurringDeletion? initialScope,
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
                _confirmDelete(
                  context,
                  deleteConfirmationMessage,
                  initialScope,
                  onDelete,
                );
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
    RecurringDeletion? initialScope,
    ValueChanged<RecurringDeletion> onDelete,
  ) {
    var scope = initialScope ?? RecurringDeletion.afterThisMonth;

    showFrostedDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => FrostedDialog(
          title: 'Confirmer la suppression',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              if (initialScope != null) ...[
                const SizedBox(height: FrostedSpacing.sp4),
                _ScopeToggle(
                  scope: scope,
                  onChanged: (value) => setState(() => scope = value),
                ),
              ],
            ],
          ),
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
                onDelete(scope);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeToggle extends StatelessWidget {
  final RecurringDeletion scope;
  final ValueChanged<RecurringDeletion> onChanged;

  const _ScopeToggle({required this.scope, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final takesThisMonth = scope == RecurringDeletion.includingThisMonth;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TransactionActionsSheet._scopeLabel,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: FrostedSpacing.sp1),
              Text(
                takesThisMonth
                    ? TransactionActionsSheet._dropsTheMonth
                    : TransactionActionsSheet._keepsTheMonth,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: FrostedSpacing.sp3),
        FrostedSwitch(
          value: takesThisMonth,
          onChanged: (value) => onChanged(
            value
                ? RecurringDeletion.includingThisMonth
                : RecurringDeletion.afterThisMonth,
          ),
        ),
      ],
    );
  }
}
