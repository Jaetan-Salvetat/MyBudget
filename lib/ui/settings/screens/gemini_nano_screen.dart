import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/models/gemini_nano_download.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/settings/gemini_nano_provider.dart';

const int _bytesPerMegabyte = 1024 * 1024;

class GeminiNanoScreen extends ConsumerWidget {
  const GeminiNanoScreen({super.key});

  static const String introduction =
      'Gemini Nano tourne sur le téléphone, via le service système AICore. '
      'Le modèle est partagé avec les autres apps : il ne pèse pas sur MyBudget '
      'et rien ne part sur Internet.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GeminiNanoStatus> status = ref.watch(
      geminiNanoStatusProvider,
    );

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Gemini Nano',
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          FrostedSpacing.sp4,
          FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
          FrostedSpacing.sp4,
          FrostedSpacing.sp6,
        ),
        children: [
          Text(
            introduction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: FrostedSpacing.sp5),
          switch (status) {
            AsyncData(:final value) => _Status(status: value),
            AsyncError() => const _Note(
              icon: Symbols.error_rounded,
              text: 'Impossible de lire l\'état de Gemini Nano.',
            ),
            _ => const Center(child: FrostedCircularProgress()),
          },
        ],
      ),
    );
  }
}

class _Status extends ConsumerWidget {
  const _Status({required this.status});

  final GeminiNanoStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GeminiNanoDownload? download = ref.watch(geminiNanoDownloadProvider);

    if (download != null && status != GeminiNanoStatus.available) {
      return _Download(step: download);
    }

    return switch (status) {
      GeminiNanoStatus.available => const _Note(
        icon: Symbols.check_circle_rounded,
        text: 'Le modèle est installé et prêt.',
      ),
      GeminiNanoStatus.downloading => _Action(
        note:
            'Le système télécharge déjà le modèle. Il se partage avec les '
            'autres apps de l\'appareil.',
        label: 'Suivre le téléchargement',
      ),
      GeminiNanoStatus.downloadable => _Action(
        note:
            'Le modèle n\'est pas encore sur l\'appareil. Le téléchargement '
            'est géré par le système et se fait une seule fois.',
        label: 'Télécharger le modèle',
      ),
      GeminiNanoStatus.unavailable => const _Note(
        icon: Symbols.block_rounded,
        text:
            'Cet appareil ne propose pas Gemini Nano. Il faut un téléphone '
            'compatible AICore, à jour, et dont le bootloader est verrouillé.',
      ),
    };
  }
}

class _Action extends ConsumerWidget {
  const _Action({required this.note, required this.label});

  final String note;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Note(icon: Symbols.download_rounded, text: note),
        const SizedBox(height: FrostedSpacing.sp5),
        FrostedButton.filled(
          label: label,
          expanded: true,
          onPressed: () => ref.read(geminiNanoDownloadProvider.notifier).start(),
        ),
      ],
    );
  }
}

class _Download extends ConsumerWidget {
  const _Download({required this.step});

  final GeminiNanoDownload step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (step case GeminiNanoDownloadFailed(:final failure)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Note(icon: Symbols.error_rounded, text: failure.message),
          if (!failure.isPermanent) ...[
            const SizedBox(height: FrostedSpacing.sp5),
            FrostedButton.outlined(
              label: 'Réessayer',
              expanded: true,
              onPressed: () =>
                  ref.read(geminiNanoDownloadProvider.notifier).start(),
            ),
          ],
        ],
      );
    }

    if (step is GeminiNanoDownloadCompleted) {
      return const _Note(
        icon: Symbols.check_circle_rounded,
        text: 'Le modèle est installé et prêt.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostedLinearProgress(value: _ratio),
        const SizedBox(height: FrostedSpacing.sp3),
        Text(
          _label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  double? get _ratio => switch (step) {
    GeminiNanoDownloadProgress(:final ratio) => ratio,
    _ => null,
  };

  String get _label {
    if (step case GeminiNanoDownloadProgress(
      :final downloadedBytes,
      :final totalBytes,
      :final ratio,
    ) when ratio != null) {
      return '${(ratio * 100).round()} % · ${_megabytes(downloadedBytes)} '
          'sur ${_megabytes(totalBytes)}';
    }
    return 'Téléchargement en cours…';
  }

  static String _megabytes(int bytes) =>
      '${(bytes / _bytesPerMegabyte).round()} Mo';
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: FrostedSpacing.sp3),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
