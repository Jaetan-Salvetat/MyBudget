import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/secure_storage_service.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/settings/widgets/gemini_api_key_bottom_sheet.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';

class ConfigurationSection extends ConsumerStatefulWidget {
  const ConfigurationSection({super.key});

  @override
  ConsumerState<ConfigurationSection> createState() =>
      _ConfigurationSectionState();
}

class _ConfigurationSectionState extends ConsumerState<ConfigurationSection> {
  bool _hasCustomKey = false;

  @override
  void initState() {
    super.initState();
    _loadKeyStatus();
  }

  Future<void> _loadKeyStatus() async {
    final hasKey = await SecureStorageService.hasGeminiApiKey();
    if (mounted) {
      setState(() => _hasCustomKey = hasKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Configuration',
      children: [
        SettingsTile(
          title: 'Ajout rapide (IA)',
          subtitle:
              '${QuickAddNotifier.monthlyLimit - PreferencesService.getQuickAddCount()}/${QuickAddNotifier.monthlyLimit} requêtes restantes ce mois',
          leading: const Icon(Symbols.bolt_rounded),
        ),
        SettingsTile(
          title: _hasCustomKey
              ? 'Clé API personnelle active'
              : 'Utiliser ma propre clé API',
          subtitle: _hasCustomKey
              ? 'Vous utilisez vos propres quotas Gemini'
              : 'Recommandé pour éviter les limites partagées',
          leading: Icon(
            _hasCustomKey ? Symbols.vpn_key_rounded : Symbols.vpn_key_rounded,
          ),
          onTap: () async {
            await GeminiApiKeyBottomSheet.show(
              context: context,
              hasExistingKey: _hasCustomKey,
            );
            _loadKeyStatus();
          },
        ),
      ],
    );
  }
}
