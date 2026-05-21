import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/data/import_entity_report.dart';
import 'package:mybudget/core/services/data/import_report.dart';
import 'package:mybudget/utils/app_utils.dart';
import 'package:mybudget/ui/settings/data_provider.dart';

class DataManagementDialogs {
  static void showImportConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    String jsonContent,
  ) {
    FrostedDialog.show(
      context: context,
      title: const Text('Importer des données'),
      content: const Text(
        'Voulez-vous importer ces données ? Cette action remplacera toutes vos données actuelles.',
      ),
      actions: [
        FrostedTonalButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            showImportProgressDialog(context, ref, jsonContent);
          },
          child: const Text('Importer'),
        ),
      ],
    );
  }

  static Future<void> showImportProgressDialog(
    BuildContext context,
    WidgetRef ref,
    String jsonContent,
  ) async {
    FrostedDialog.show(
      context: context,
      title: const Text('Importation en cours'),
      content: Consumer(
        builder: (context, watchRef, child) {
          final state = watchRef.watch(dataProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Veuillez ne pas quitter l\'application pendant l\'importation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              FrostedLinearProgressIndicator(value: state.importProgress),
              const SizedBox(height: 10),
              Text(
                state.importStatus,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );

    await ref.read(dataProvider.notifier).importUserData(jsonContent);

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      final dataState = ref.read(dataProvider);
      if (dataState.error.isNotEmpty) {
        FrostedDialog.show(
          context: context,
          title: const Text('Erreur d\'importation'),
          content: Text(dataState.error),
          actions: [
            FrostedTonalButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      } else if (dataState.importReport != null) {
        showImportReportDialog(context, dataState.importReport!);
      } else {
        _showRestartDialog(
          context,
          title: 'Importation réussie',
          message:
              'Les données ont été importées avec succès.\n\n'
              'L\'application va redémarrer pour prendre en compte les changements.',
        );
      }
    }
  }

  static void showImportReportDialog(
    BuildContext context,
    ImportReport report,
  ) {
    FrostedDialog.show(
      context: context,
      title: const Text('Rapport d\'importation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...report.all.map(
            (entity) => _ImportReportRow(entity: entity),
          ),
          if (report.hasWarnings) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Symbols.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Certains éléments ont été ignorés ou ont échoué.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'L\'application va redémarrer pour prendre en compte les changements.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        FrostedFilledButton(
          onPressed: () => AppUtils.restartApp(context),
          child: const Text('Redémarrer'),
        ),
      ],
    );
  }

  static Future<void> showDeleteDataConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    FrostedDialog.show(
      context: context,
      title: const Text('Supprimer toutes les données'),
      content: const Text(
        'Êtes-vous sûr de vouloir supprimer toutes vos données ? Cette action est irréversible.',
      ),
      actions: [
        FrostedTonalButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            showDeleteProgressDialog(context, ref);
          },
          child: const Text('Supprimer'),
        ),
      ],
    );
  }

  static Future<void> showDeleteProgressDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    FrostedDialog.show(
      context: context,
      title: const Text('Suppression en cours'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Veuillez patienter pendant la suppression des données...',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          FrostedCircularProgressIndicator(),
        ],
      ),
    );

    await ref.read(dataProvider.notifier).deleteAllUserData();

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      final error = ref.read(dataProvider).error;
      if (error.isNotEmpty) {
        FrostedDialog.show(
          context: context,
          title: const Text('Erreur de suppression'),
          content: Text(error),
          actions: [
            FrostedTonalButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      } else {
        _showRestartDialog(
          context,
          title: 'Suppression réussie',
          message:
              'Toutes les données ont été supprimées avec succès.\n\n'
              'L\'application va redémarrer pour prendre en compte les changements.',
        );
      }
    }
  }

  static void _showRestartDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    FrostedDialog.show(
      context: context,
      title: Text(title),
      content: Text(message),
      actions: [
        FrostedFilledButton(
          onPressed: () => AppUtils.restartApp(context),
          child: const Text('Redémarrer'),
        ),
      ],
    );
  }
}

class _ImportReportRow extends StatelessWidget {
  final ImportEntityReport entity;

  const _ImportReportRow({required this.entity});

  @override
  Widget build(BuildContext context) {
    if (entity.total == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            entity.hasIssues ? Symbols.warning_amber_rounded : Symbols.check_circle_rounded,
            color: entity.hasIssues
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entity.entityName,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '${entity.imported}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (entity.skipped > 0) ...[
            const SizedBox(width: 8),
            Text(
              '(${entity.skipped} ignorés)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (entity.errors.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '(${entity.errors.length} erreurs)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
