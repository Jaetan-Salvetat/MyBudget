import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/theme/flutter_material_mapper.dart';
import 'package:mybudget/ui/common/widgets/frosted_container.dart';
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
      appBar: const FrostedTopBar(title: 'Mise à jour'),
      bottomNavigationBar: state.availableUpdate != null
          ? _buildBottomBar(state, theme)
          : null,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
        child: _buildContent(context, state, theme),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UpdateState state,
    ThemeData theme,
  ) {
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

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset('assets/logo.png', width: 80, height: 80),
    );
  }

  Widget _buildChecking(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogo(),
          const SizedBox(height: 24),
          const FrostedCircularProgress(),
          const SizedBox(height: 12),
          Text(
            'Recherche de mises à jour...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
          _buildLogo(),
          const SizedBox(height: 24),
          Text(
            'Vous êtes à jour',
            style: theme.textTheme.titleLarge?.copyWith(
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
          FrostedButton.tonal(
            label: 'Vérifier à nouveau',
            onPressed: () =>
                ref.read(updateProvider.notifier).checkForUpdates(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateAvailable(UpdateState state, ThemeData theme) {
    final release = state.availableUpdate!;
    final asset = release.defaultApkAsset;
    final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');

    final metaInfo = StringBuffer(
      'Publiée le ${dateFormat.format(release.publishedAt)}',
    );
    if (asset != null) {
      metaInfo.write(' · ${_formatFileSize(asset.size)}');
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Center(child: _buildLogo()),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Version ${release.version} disponible',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            metaInfo.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (release.notes.isNotEmpty) ...[
          const SizedBox(height: 24),
          const FrostedDivider(),
          const SizedBox(height: 16),
          MarkdownBody(
            data: release.notes,
            styleSheet: MarkdownStyleSheet.fromTheme(
              FlutterMaterialMapper.toLegacyThemeData(theme),
            ).copyWith(p: theme.textTheme.bodyMedium),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBottomBar(UpdateState state, ThemeData theme) {
    return FrostedContainer(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.error != null) ...[
            Row(
              children: [
                Icon(
                  Symbols.error_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 12),
          ],
          if (state.isDownloading) ...[
            FrostedLinearProgress(value: state.downloadProgress),
            const SizedBox(height: 8),
            Text(
              'Téléchargement... ${(state.downloadProgress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodyMedium,
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FrostedButton.filled(
                label: 'Télécharger et installer',
                onPressed: () =>
                    ref.read(updateProvider.notifier).downloadUpdate(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Version actuelle : ${state.currentVersion ?? ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(UpdateState state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogo(),
          const SizedBox(height: 24),
          Text(
            'Impossible de vérifier',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FrostedButton.tonal(
            label: 'Réessayer',
            onPressed: () =>
                ref.read(updateProvider.notifier).checkForUpdates(),
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
