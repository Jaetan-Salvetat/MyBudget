import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/core/services/secure_storage_service.dart';
import 'package:mybudget/ui/settings/widgets/gemini_api_key_bottom_sheet.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/utils/app_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class ConfigurationSection extends ConsumerStatefulWidget {
  const ConfigurationSection({super.key});

  @override
  ConsumerState<ConfigurationSection> createState() =>
      _ConfigurationSectionState();
}

class _ConfigurationSectionState extends ConsumerState<ConfigurationSection> {
  bool _hasCustomKey = false;
  late bool _updateEnabled;
  late int _updateInterval;

  static const Map<int, String> _intervalOptions = {
    1: '1 heure',
    6: '6 heures',
    12: '12 heures',
    24: '24 heures',
    48: '48 heures',
    168: 'Hebdomadaire',
  };

  @override
  void initState() {
    super.initState();
    _loadKeyStatus();
    _updateEnabled = PreferencesService.isBackgroundCheckEnabled();
    _updateInterval = PreferencesService.getBackgroundCheckInterval();
  }

  Future<void> _loadKeyStatus() async {
    final hasKey = await SecureStorageService.hasGeminiApiKey();
    if (mounted) {
      setState(() => _hasCustomKey = hasKey);
    }
  }

  void _showRestartDialog() {
    FrostedDialog.show(
      context: context,
      title: const Text('Redémarrage requis'),
      content: Text(
        'L\'application va redémarrer pour prendre en compte les changements.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Plus tard'),
        ),
        FrostedFilledButton(
          onPressed: () => AppUtils.restartApp(context),
          child: const Text('Redémarrer'),
        ),
      ],
    );
  }

  Future<void> _onToggleChanged(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _updateEnabled = true);
        await PreferencesService.setBackgroundCheckEnabled(true);
        if (mounted) _showRestartDialog();
      } else {
        setState(() => _updateEnabled = false);
        await PreferencesService.setBackgroundCheckEnabled(false);
        if (mounted) {
          FrostedSnackbar.show(
            context,
            message:
                'La permission de notification est requise pour les vérifications automatiques.',
          );
        }
      }
    } else {
      setState(() => _updateEnabled = false);
      await PreferencesService.setBackgroundCheckEnabled(false);
      if (mounted) _showRestartDialog();
    }
  }

  Future<void> _onIntervalChanged(int? value) async {
    if (value == null) return;
    setState(() => _updateInterval = value);
    await PreferencesService.setBackgroundCheckInterval(value);
    if (mounted) _showRestartDialog();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsSection(
      title: 'Configuration',
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sync,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Vérification auto',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
              FrostedSwitch(
                value: _updateEnabled,
                onChanged: _onToggleChanged,
              ),
            ],
          ),
        ),
        if (_updateEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Fréquence',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
                FrostedDropdown<int>(
                  value: _updateInterval,
                  items: _intervalOptions.entries
                      .map((e) => DropdownMenuItem<int>(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: _onIntervalChanged,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
