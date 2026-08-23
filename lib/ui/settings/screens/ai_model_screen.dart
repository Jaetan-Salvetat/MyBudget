import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';

/// Le modèle appelé avec la clé de l'utilisateur. Du plus rapide au plus
/// capable : c'est sa clé qui paie, à lui de placer le curseur.
class AiModelScreen extends ConsumerWidget {
  const AiModelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AiProvider provider = ref.watch(selectedAiProviderProvider);
    final AiModel selected = ref.watch(selectedAiModelProvider);
    final List<AiModel> models = AiModel.forProvider(provider);

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Modèle',
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
          FrostedListSection(
            label: provider.label,
            tiles: [
              for (final model in models)
                FrostedListTile(
                  title: model.label,
                  subtitle: model.description,
                  leading: FrostedRadio<AiModel>(
                    value: model,
                    groupValue: selected,
                    onChanged: (_) => _select(ref, model),
                  ),
                  onTap: () => _select(ref, model),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _select(WidgetRef ref, AiModel model) async {
    await ref.read(selectedAiModelProvider.notifier).select(model);
    ref.invalidate(quickAddEngineProvider);
  }
}
