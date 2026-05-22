import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/local_model_catalog.dart';
import 'package:mybudget/core/enums/local_model_status.dart';
import 'package:mybudget/ui/common/widgets/solid_card.dart';
import 'package:mybudget/ui/settings/local_model_provider.dart';

class LocalModelBottomSheet extends ConsumerStatefulWidget {
  const LocalModelBottomSheet({super.key});

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    await ref.read(localModelProvider.notifier).checkDiskSpace();
    if (!context.mounted) return;
    return FrostedBottomSheet.show(
      context: context,
      title: 'IA locale',
      child: const LocalModelBottomSheet(),
    );
  }

  @override
  ConsumerState<LocalModelBottomSheet> createState() =>
      _LocalModelBottomSheetState();
}

class _LocalModelBottomSheetState extends ConsumerState<LocalModelBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localModelProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.error != null) ...[
            _buildInfoCard(
              context,
              icon: Symbols.error_rounded,
              color: theme.colorScheme.error,
              title: 'Erreur',
              children: [
                Text(
                  state.error!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          switch (state.status) {
            LocalModelStatus.none => _buildModelSelection(context, state),
            LocalModelStatus.downloading =>
              _buildDownloading(context, state),
            LocalModelStatus.ready => _buildReady(context, state),
          },
        ],
      ),
    );
  }

  Widget _buildModelSelection(BuildContext context, LocalModelState state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          context,
          icon: Symbols.smart_toy_rounded,
          color: theme.colorScheme.primary,
          title: 'Catégorisation intelligente',
          children: [
            Text(
              'Catégorise automatiquement vos dépenses '
              'à partir de vos saisies en langage naturel. '
              'Fonctionne 100% hors ligne une fois installé.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Symbols.wifi_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Wi-Fi recommandé',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (state.availableSpaceGb != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Symbols.storage_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Disponible : ${state.availableSpaceGb!.toStringAsFixed(1)} Go',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        for (final config in LocalModelCatalog.models) ...[
          _buildModelTile(context, config, state),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildModelTile(
    BuildContext context,
    LocalModelConfig config,
    LocalModelState state,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(localModelProvider.notifier);
    final hasSpace = state.availableSpaceGb != null &&
        state.availableSpaceGb! >= config.requiredSpaceGb;

    return SolidCard(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.displayName,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  config.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FrostedFilledButton(
            onPressed: hasSpace
                ? () async {
                    Navigator.pop(context);
                    try {
                      await notifier.startDownload(config);
                    } catch (e) {
                      if (context.mounted) {
                        FrostedSnackbar.show(
                          context,
                          message: 'Erreur lors de l\'installation : $e',
                        );
                      }
                    }
                  }
                : null,
            child: const Text('Installer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloading(BuildContext context, LocalModelState state) {
    final theme = Theme.of(context);
    final percent = (state.downloadProgress * 100).toStringAsFixed(0);
    final modelName = state.installedModel?.displayName ?? 'Modèle';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$modelName — $percent%',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: FrostedLinearProgressIndicator(
            value: state.downloadProgress,
            minHeight: 8,
            backgroundColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.08),
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FrostedTextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(localModelProvider.notifier).cancelDownload();
              } catch (e) {
                if (context.mounted) {
                  FrostedSnackbar.show(
                    context,
                    message: 'Erreur lors de l\'annulation : $e',
                  );
                }
              }
            },
            child: Text(
              'Annuler',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReady(BuildContext context, LocalModelState state) {
    final theme = Theme.of(context);
    final config = state.installedModel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          context,
          icon: Symbols.check_circle_rounded,
          color: Colors.green,
          title: 'IA locale activée',
          children: [
            Text(
              'Le quick-add catégorise automatiquement vos saisies '
              'directement sur votre appareil.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (config != null) ...[
          Row(
            children: [
              Icon(
                Symbols.smart_toy_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                config.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Icon(
              Symbols.hard_drive_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Espace utilisé : ${config?.sizeGb ?? '?'} Go',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FrostedTextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(localModelProvider.notifier).deleteModel();
              } catch (e) {
                if (context.mounted) {
                  FrostedSnackbar.show(
                    context,
                    message: 'Erreur lors de la suppression : $e',
                  );
                }
              }
            },
            child: Text(
              'Supprimer le modèle',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
