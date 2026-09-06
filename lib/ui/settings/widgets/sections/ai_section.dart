import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/cloud_engine_availability.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/data/provider/ai_settings_provider.dart';
import 'package:mybudget/data/provider/gemini_nano_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/ui/settings/screens/gemini_cloud_screen.dart';
import 'package:mybudget/ui/settings/screens/gemini_nano_screen.dart';
import 'package:mybudget/ui/settings/screens/quick_add_engine_screen.dart';

class AiSection extends ConsumerWidget {
  const AiSection({super.key});

  static const String naturalInputTitle = 'Saisie en langage naturel';

  static const String naturalInputSubtitle =
      'Écrire « resto 25 » au lieu de remplir un formulaire';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool naturalInputEnabled = ref.watch(quickAddEnabledProvider);
    final bool exposesEngine = ref
        .watch(buildFlavorProvider)
        .exposesQuickAddEngineSettings;
    final QuickAddEngineMode engine = ref.watch(quickAddEngineModeProvider);
    final bool usesCloud = engine == QuickAddEngineMode.apiKey;
    final GeminiNanoStatus? nano = ref.watch(geminiNanoStatusProvider).value;

    void setEnabled(bool enabled) =>
        ref.read(quickAddEnabledProvider.notifier).setEnabled(enabled);

    return FrostedListSection(
      label: 'Intelligence artificielle',
      tiles: [
        FrostedListTile(
          title: naturalInputTitle,
          subtitle: naturalInputSubtitle,
          leading: const FrostedListAvatar(icon: Symbols.bolt_rounded),
          trailing: FrostedSwitch(
            value: naturalInputEnabled,
            onChanged: setEnabled,
          ),
          onTap: () => setEnabled(!naturalInputEnabled),
        ),
        if (exposesEngine)
          FrostedListTile(
            title: 'Moteur d\'analyse',
            subtitle: engine.label,
            leading: const FrostedListAvatar(icon: Symbols.tune_rounded),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => _open(context, const QuickAddEngineScreen()),
          ),
        if (exposesEngine && usesCloud && isCloudQuickAddEngineAvailable)
          FrostedListTile(
            title: GeminiCloudScreen.title,
            subtitle: _cloudSubtitle(ref),
            leading: const FrostedListAvatar(icon: Symbols.cloud_rounded),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => _open(context, const GeminiCloudScreen()),
          ),
        if (!usesCloud && nano != null && nano.isSelectable)
          FrostedListTile(
            title: 'Gemini Nano',
            subtitle: _nanoSubtitle(ref, nano),
            leading: const FrostedListAvatar(icon: Symbols.neurology_rounded),
            trailing: const Icon(Symbols.chevron_right_rounded),
            onTap: () => _open(context, const GeminiNanoScreen()),
          ),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  String _cloudSubtitle(WidgetRef ref) {
    final bool hasKey = ref.watch(hasStoredApiKeyProvider).value ?? false;
    if (!hasKey) return 'Aucune clé enregistrée';

    return 'Clé enregistrée · ${ref.watch(selectedAiModelProvider).label}';
  }

  String _nanoSubtitle(WidgetRef ref, GeminiNanoStatus status) {
    if (!status.isReady) return 'Modèle pas encore installé';

    return ref.watch(geminiNanoScanProvider)
        ? 'Lit les tickets sur l\'appareil'
        : 'Installé, pas encore utilisé';
  }
}
