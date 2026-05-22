import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/enums/local_model_status.dart';
import 'package:mybudget/ui/settings/local_model_provider.dart';
import 'package:mybudget/ui/settings/widgets/local_model_bottom_sheet.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';

class LocalAiSection extends ConsumerWidget {
  const LocalAiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localModelProvider);

    return SettingsSection(
      title: 'IA locale',
      children: [
        if (state.status == LocalModelStatus.downloading)
          _DownloadingTile(state: state, ref: ref)
        else
          SettingsTile(
            title: state.installedModel?.displayName ?? 'Modèle IA',
            subtitle: _subtitle(state),
            leading: const Icon(Symbols.smart_toy_rounded),
            onTap: () => LocalModelBottomSheet.show(
              context: context,
              ref: ref,
            ),
          ),
      ],
    );
  }

  String _subtitle(LocalModelState state) {
    return switch (state.status) {
      LocalModelStatus.none => state.error ?? 'Non installée',
      LocalModelStatus.downloading => 'Téléchargement…',
      LocalModelStatus.ready =>
        'Prête · ${state.installedModel?.sizeGb.toStringAsFixed(1) ?? '?'} Go',
    };
  }
}

class _DownloadingTile extends StatelessWidget {
  final LocalModelState state;
  final WidgetRef ref;

  const _DownloadingTile({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (state.downloadProgress * 100).toStringAsFixed(0);
    final modelName = state.installedModel?.displayName ?? 'Modèle IA';

    return InkWell(
      onTap: () => LocalModelBottomSheet.show(context: context, ref: ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Symbols.smart_toy_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modelName,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Téléchargement… $percent%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: FrostedLinearProgressIndicator(
                      value: state.downloadProgress,
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
