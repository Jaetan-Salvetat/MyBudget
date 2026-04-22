import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/core/services/secure_storage_service.dart';
import 'package:mybudget/ui/settings/widgets/gemini_api_key_bottom_sheet.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';

class GeminiSection extends ConsumerStatefulWidget {
  const GeminiSection({super.key});

  @override
  ConsumerState<GeminiSection> createState() => _GeminiSectionState();
}

class _GeminiSectionState extends ConsumerState<GeminiSection> {
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
      title: 'Scan de tickets',
      children: [
        SettingsTile(
          title: _hasCustomKey
              ? 'Clé API personnelle active'
              : 'Utiliser ma propre clé API',
          subtitle: _hasCustomKey
              ? 'Vous utilisez vos propres quotas Gemini'
              : 'Recommandé pour éviter les limites partagées',
          leading: Icon(
            _hasCustomKey ? Icons.vpn_key : Icons.vpn_key_outlined,
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
