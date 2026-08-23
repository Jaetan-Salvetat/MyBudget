import 'package:material_ui/material_ui.dart';
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
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Importer des données',
        body: const Text(
          'Voulez-vous importer ces données ? Cette action remplacera toutes vos données actuelles.',
        ),
        actions: [
          FrostedButton.tonal(
            label: 'Annuler',
            onPressed: () => Navigator.of(context).pop(),
          ),
          FrostedButton.filled(
            label: 'Importer',
            onPressed: () {
              Navigator.of(context).pop();
              showImportProgressDialog(context, ref, jsonContent);
            },
          ),
        ],
      ),
    );
  }

  static Future<void> showImportProgressDialog(
    BuildContext context,
    WidgetRef ref,
    String jsonContent,
  ) async {
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Importation en cours',
        body: Consumer(
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
                FrostedLinearProgress(value: state.importProgress),
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
      ),
    );

    await ref.read(dataProvider.notifier).importUserData(jsonContent);

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      final dataState = ref.read(dataProvider);
      if (dataState.error.isNotEmpty) {
        showFrostedDialog<void>(
          context: context,
          builder: (_) => FrostedDialog(
            title: 'Erreur d\'importation',
            body: Text(dataState.error),
            actions: [
              FrostedButton.tonal(
                label: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
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
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Rapport d\'importation',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...report.all.map((entity) => _ImportReportRow(entity: entity)),
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
          FrostedButton.filled(
            label: 'Redémarrer',
            onPressed: () => AppUtils.restartApp(context),
          ),
        ],
      ),
    );
  }

  static Future<void> showDeleteDataConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Supprimer toutes les données',
        body: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes vos données ? Cette action est irréversible.',
        ),
        actions: [
          FrostedButton.tonal(
            label: 'Annuler',
            onPressed: () => Navigator.of(context).pop(),
          ),
          FrostedButton.filled(
            label: 'Supprimer',
            onPressed: () {
              Navigator.of(context).pop();
              showDeleteProgressDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  static Future<void> showDeleteProgressDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Suppression en cours',
        body: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Veuillez patienter pendant la suppression des données...',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            FrostedCircularProgress(),
          ],
        ),
      ),
    );

    await ref.read(dataProvider.notifier).deleteAllUserData();

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      final error = ref.read(dataProvider).error;
      if (error.isNotEmpty) {
        showFrostedDialog<void>(
          context: context,
          builder: (_) => FrostedDialog(
            title: 'Erreur de suppression',
            body: Text(error),
            actions: [
              FrostedButton.tonal(
                label: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
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
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: title,
        body: Text(message),
        actions: [
          FrostedButton.filled(
            label: 'Redémarrer',
            onPressed: () => AppUtils.restartApp(context),
          ),
        ],
      ),
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
            entity.hasIssues
                ? Symbols.warning_amber_rounded
                : Symbols.check_circle_rounded,
            color: entity.hasIssues
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(entity.entityName, style: theme.textTheme.bodyMedium),
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
