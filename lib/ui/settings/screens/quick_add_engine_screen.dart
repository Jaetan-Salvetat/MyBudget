import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/screens/api_key_screen.dart';

class QuickAddEngineScreen extends ConsumerWidget {
  const QuickAddEngineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final QuickAddEngineMode mode = ref.watch(quickAddEngineModeProvider);
    final bool hasKey = ref.watch(hasStoredApiKeyProvider).value ?? false;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Moteur d\'analyse',
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
            tiles: [
              FrostedListTile(
                title: QuickAddEngineMode.onDevice.label,
                subtitle:
                    'Le modèle embarqué de MyBudget. Fonctionne hors ligne.',
                leading: FrostedRadio<QuickAddEngineMode>(
                  value: QuickAddEngineMode.onDevice,
                  groupValue: mode,
                  onChanged: (_) => _select(ref, QuickAddEngineMode.onDevice),
                ),
                onTap: () => _select(ref, QuickAddEngineMode.onDevice),
              ),
              FrostedListTile(
                title: 'Clé API personnelle',
                subtitle:
                    'Vous fournissez la clé d\'un service externe. '
                    'Votre saisie lui est envoyée.',
                leading: FrostedRadio<QuickAddEngineMode>(
                  value: QuickAddEngineMode.apiKey,
                  groupValue: mode,
                  onChanged: (_) => _selectApiKey(context, ref, hasKey),
                ),
                onTap: () => _selectApiKey(context, ref, hasKey),
              ),
            ],
          ),
          const SizedBox(height: FrostedSpacing.sp4),
          _Note(
            icon: Symbols.info_rounded,
            color: colors.onSurfaceVariant,
            text:
                'Le modèle embarqué reste utilisé en secours dans tous les cas.',
          ),
        ],
      ),
    );
  }

  Future<void> _select(WidgetRef ref, QuickAddEngineMode mode) async {
    await ref.read(quickAddEngineModeProvider.notifier).setMode(mode);
    ref.invalidate(quickAddEngineProvider);
  }

  Future<void> _selectApiKey(
    BuildContext context,
    WidgetRef ref,
    bool hasKey,
  ) async {
    if (hasKey) {
      await _select(ref, QuickAddEngineMode.apiKey);
      return;
    }
    await _openKeyScreen(context);
  }

  Future<void> _openKeyScreen(BuildContext context) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ApiKeyScreen()),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: FrostedSpacing.sp3),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
