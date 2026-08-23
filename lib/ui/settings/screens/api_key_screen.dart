import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mybudget/core/enums/ai_model.dart';
import 'package:mybudget/core/enums/ai_provider.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/models/api_key_check.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:mybudget/ui/settings/widgets/ai_cloud_consent_dialog.dart';

/// Le seul endroit où la clé se saisit, pour l'ajout rapide comme pour le scan
/// de ticket. Rien n'est enregistré tant qu'un appel n'a pas abouti.
class ApiKeyScreen extends ConsumerStatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _isVerifying = false;
  String? _errorMessage;
  String? _noticeMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AiProvider provider = ref.watch(selectedAiProviderProvider);
    final AsyncValue<bool> hasKey = ref.watch(hasStoredApiKeyProvider);

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Clé API',
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
            'Votre clé sert à l\'ajout rapide et au scan de ticket. '
            'Elle reste sur cet appareil.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: FrostedSpacing.sp5),
          FrostedDropdown<AiProvider>(
            label: 'Service',
            value: provider,
            items: AiProvider.values
                .map(
                  (value) => FrostedDropdownItem<AiProvider>(
                    value: value,
                    label: value.label,
                  ),
                )
                .toList(),
            onChanged: _isVerifying ? null : _onProviderChanged,
          ),
          const SizedBox(height: FrostedSpacing.sp4),
          FrostedTextField(
            controller: _controller,
            label: 'Clé',
            hintText: provider.keyPlaceholder,
            helperText: hasKey.value == true
                ? 'Une clé est déjà enregistrée. Saisir une clé la remplace.'
                : provider.keyFormatHint,
            errorText: _errorMessage,
            obscureText: true,
            enabled: !_isVerifying,
            onChanged: _onKeyChanged,
          ),
          if (_noticeMessage != null) ...[
            const SizedBox(height: FrostedSpacing.sp3),
            _Notice(message: _noticeMessage!),
          ],
          const SizedBox(height: FrostedSpacing.sp5),
          FrostedButton.filled(
            label: _isVerifying ? 'Vérification…' : 'Vérifier et activer',
            expanded: true,
            onPressed: _canSubmit ? _verify : null,
          ),
          const SizedBox(height: FrostedSpacing.sp3),
          FrostedButton.text(
            label: 'Obtenir une clé sur ${provider.consoleLabel}',
            icon: Symbols.open_in_new_rounded,
            expanded: true,
            onPressed: _isVerifying ? null : () => _openConsole(provider),
          ),
          if (hasKey.value == true) ...[
            const SizedBox(height: FrostedSpacing.sp6),
            FrostedButton.outlined(
              label: 'Supprimer la clé',
              icon: Symbols.delete_rounded,
              destructive: true,
              expanded: true,
              onPressed: _isVerifying ? null : () => _confirmDelete(provider),
            ),
          ],
        ],
      ),
    );
  }

  bool get _canSubmit => !_isVerifying && _controller.text.trim().isNotEmpty;

  void _onKeyChanged(String _) {
    if (_errorMessage == null && _noticeMessage == null) {
      setState(() {});
      return;
    }
    setState(() {
      _errorMessage = null;
      _noticeMessage = null;
    });
  }

  Future<void> _onProviderChanged(AiProvider provider) async {
    _controller.clear();
    setState(() {
      _errorMessage = null;
      _noticeMessage = null;
    });
    await ref.read(selectedAiProviderProvider.notifier).select(provider);
  }

  Future<void> _openConsole(AiProvider provider) async {
    await launchUrl(
      Uri.parse(provider.consoleUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _verify() async {
    final AiProvider provider = ref.read(selectedAiProviderProvider);
    final String rawKey = _controller.text;

    if (!ref.read(aiCloudConsentProvider)) {
      final accepted = await AiCloudConsentDialog.show(context, provider);
      if (!accepted || !mounted) return;
      await ref.read(aiCloudConsentProvider.notifier).accept();
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _noticeMessage = null;
    });

    final AiModel model = ref.read(selectedAiModelProvider);
    final check = await ref
        .read(apiKeyVerifierProvider)
        .verify(provider: provider, model: model, rawKey: rawKey);

    if (!mounted) return;

    switch (check) {
      case ApiKeyAccepted(:final quotaExhausted):
        await _activate(provider, rawKey);
        if (!mounted) return;
        Navigator.pop(context, quotaExhausted);
      case ApiKeyDenied(:final message):
        setState(() {
          _isVerifying = false;
          _errorMessage = message;
        });
    }
  }

  /// L'appel a abouti : c'est seulement ici que le moteur bascule.
  Future<void> _activate(AiProvider provider, String rawKey) async {
    await ref.read(apiKeyServiceProvider).save(provider, rawKey);
    await ref
        .read(quickAddEngineModeProvider.notifier)
        .setMode(QuickAddEngineMode.apiKey);
    await ref.read(quickAddDegradationProvider.notifier).clear();
    ref.invalidate(hasStoredApiKeyProvider);
    ref.invalidate(quickAddEngineProvider);
    ref.invalidate(receiptScanServiceProvider);
  }

  Future<void> _confirmDelete(AiProvider provider) async {
    final confirmed = await showFrostedDialog<bool>(
      context: context,
      builder: (dialogContext) => FrostedDialog(
        title: 'Supprimer la clé',
        body: const Text(
          'L\'ajout rapide et le scan de ticket repasseront sans clé. '
          'Vous pourrez en saisir une nouvelle à tout moment.',
        ),
        actions: [
          FrostedButton.text(
            label: 'Annuler',
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          FrostedButton.text(
            label: 'Supprimer',
            destructive: true,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(apiKeyServiceProvider).delete(provider);
    await ref.read(quickAddEngineModeProvider.notifier).setMode(
      QuickAddEngineMode.onDevice,
    );
    await ref.read(quickAddDegradationProvider.notifier).clear();
    ref.invalidate(hasStoredApiKeyProvider);
    ref.invalidate(quickAddEngineProvider);
    ref.invalidate(receiptScanServiceProvider);

    if (!mounted) return;
    _controller.clear();
    setState(() => _noticeMessage = 'Clé supprimée.');
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
