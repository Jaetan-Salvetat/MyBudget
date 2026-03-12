import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/ui/settings/update_provider.dart';

class UpdateScreen extends ConsumerStatefulWidget {
  const UpdateScreen({super.key});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {
  @override
  void initState() {
    super.initState();
    final state = ref.read(updateProvider);
    if (state.availableUpdate == null && !state.isChecking) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(updateProvider.notifier).checkForUpdates();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateProvider);
    final theme = Theme.of(context);

    return FrostedScaffold(
      appBar: const FrostedAppBar(title: 'Mise à jour'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
        child: _buildContent(context, state, theme),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UpdateState state, ThemeData theme) {
    if (state.isChecking) {
      return _buildChecking(theme);
    }

    if (state.error != null && state.availableUpdate == null) {
      return _buildError(state, theme);
    }

    if (state.availableUpdate != null) {
      return _buildUpdateAvailable(state, theme);
    }

    return _buildUpToDate(state, theme);
  }

  Widget _buildChecking(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Recherche de mises à jour...',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildUpToDate(UpdateState state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Votre application est à jour',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version ${state.currentVersion ?? ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          FrostedTonalButton(
            onPressed: () => ref.read(updateProvider.notifier).checkForUpdates(),
            child: const Text('Vérifier à nouveau'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAvailable(UpdateState state, ThemeData theme) {
    final release = state.availableUpdate!;
    final asset = release.defaultApkAsset;
    final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        FrostedCard(
          borderRadius: 16,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.system_update,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Version ${release.version} disponible',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Publiée le ${dateFormat.format(release.publishedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (asset != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatFileSize(asset.size),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (release.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          FrostedCard(
            borderRadius: 16,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes de version',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MarkdownBody(
                    data: release.notes,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (state.error != null) ...[
          FrostedCard(
            borderRadius: 16,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (state.isDownloading) ...[
          FrostedCard(
            borderRadius: 16,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FrostedLinearProgressIndicator(
                    value: state.downloadProgress,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Téléchargement... ${(state.downloadProgress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          FrostedFilledButton(
            onPressed: () => ref.read(updateProvider.notifier).downloadUpdate(),
            child: const Text('Télécharger et installer'),
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Version actuelle : ${state.currentVersion ?? ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(UpdateState state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            state.error!,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FrostedTonalButton(
            onPressed: () => ref.read(updateProvider.notifier).checkForUpdates(),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
