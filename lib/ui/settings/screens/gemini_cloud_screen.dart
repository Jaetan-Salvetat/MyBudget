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
import 'package:mybudget/ui/settings/widgets/settings_note.dart';

class GeminiCloudScreen extends ConsumerStatefulWidget {
  const GeminiCloudScreen({super.key});

  static const String title = 'Gemini cloud';

  static const String introduction =
      'Votre clé sert à l\'ajout rapide et au scan de ticket. '
      'Elle reste sur cet appareil.';

  static const String savedNotice = 'Clé enregistrée.';

  static const String deletedNotice = 'Clé supprimée.';

  static const String quotaNotice =
      'Clé valide, mais son quota est déjà épuisé. Le service refusera les '
      'demandes jusqu\'à sa remise à zéro.';

  @override
  ConsumerState<GeminiCloudScreen> createState() => _GeminiCloudScreenState();
}

class _GeminiCloudScreenState extends ConsumerState<GeminiCloudScreen> {
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
    final bool hasKey = ref.watch(hasStoredApiKeyProvider).value ?? false;

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: GeminiCloudScreen.title,
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
            GeminiCloudScreen.introduction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: FrostedSpacing.sp5),
          _KeyForm(
            provider: provider,
            controller: _controller,
            hasKey: hasKey,
            isVerifying: _isVerifying,
            errorMessage: _errorMessage,
            noticeMessage: _noticeMessage,
            onKeyChanged: _onKeyChanged,
            onProviderChanged: _onProviderChanged,
            onSubmit: _verify,
            onOpenConsole: () => _openConsole(provider),
          ),
          if (hasKey) ...[
            const SizedBox(height: FrostedSpacing.sp6),
            const _ModelPicker(),
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

    final bool consented = await AiCloudConsentDialog.show(context, provider);
    if (!consented || !mounted) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _noticeMessage = null;
    });

    final AiModel model = ref.read(selectedAiModelProvider);
    final ApiKeyCheck check = await ref
        .read(apiKeyVerifierProvider)
        .verify(provider: provider, model: model, rawKey: rawKey);

    if (!mounted) return;

    switch (check) {
      case ApiKeyAccepted(:final quotaExhausted):
        await _activate(provider, rawKey);
        if (!mounted) return;
        _controller.clear();
        setState(() {
          _isVerifying = false;
          _noticeMessage = quotaExhausted
              ? GeminiCloudScreen.quotaNotice
              : GeminiCloudScreen.savedNotice;
        });
      case ApiKeyDenied(:final message):
        setState(() {
          _isVerifying = false;
          _errorMessage = message;
        });
    }
  }

  Future<void> _activate(AiProvider provider, String rawKey) async {
    await ref.read(apiKeyServiceProvider).save(provider, rawKey);
    await ref
        .read(quickAddEngineModeProvider.notifier)
        .setMode(QuickAddEngineMode.apiKey);
    _refreshEngines();
  }

  Future<void> _confirmDelete(AiProvider provider) async {
    final bool? confirmed = await showFrostedDialog<bool>(
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
    await ref
        .read(quickAddEngineModeProvider.notifier)
        .setMode(QuickAddEngineMode.onDevice);
    _refreshEngines();

    if (!mounted) return;
    _controller.clear();
    setState(() => _noticeMessage = GeminiCloudScreen.deletedNotice);
  }

  void _refreshEngines() {
    ref.invalidate(hasStoredApiKeyProvider);
    ref.invalidate(quickAddEngineProvider);
    ref.invalidate(cloudReceiptReaderProvider);
  }
}

class _KeyForm extends StatelessWidget {
  const _KeyForm({
    required this.provider,
    required this.controller,
    required this.hasKey,
    required this.isVerifying,
    required this.errorMessage,
    required this.noticeMessage,
    required this.onKeyChanged,
    required this.onProviderChanged,
    required this.onSubmit,
    required this.onOpenConsole,
  });

  final AiProvider provider;
  final TextEditingController controller;
  final bool hasKey;
  final bool isVerifying;
  final String? errorMessage;
  final String? noticeMessage;
  final ValueChanged<String> onKeyChanged;
  final ValueChanged<AiProvider> onProviderChanged;
  final VoidCallback onSubmit;
  final VoidCallback onOpenConsole;

  bool get _canSubmit => !isVerifying && controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          onChanged: isVerifying ? null : onProviderChanged,
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        FrostedTextField(
          controller: controller,
          label: 'Clé',
          hintText: provider.keyPlaceholder,
          helperText: hasKey
              ? 'Une clé est déjà enregistrée. Saisir une clé la remplace.'
              : provider.keyFormatHint,
          errorText: errorMessage,
          obscureText: true,
          enabled: !isVerifying,
          onChanged: onKeyChanged,
        ),
        if (noticeMessage != null) ...[
          const SizedBox(height: FrostedSpacing.sp3),
          SettingsNote(
            icon: Symbols.info_rounded,
            text: noticeMessage!,
          ),
        ],
        const SizedBox(height: FrostedSpacing.sp5),
        FrostedButton.filled(
          label: isVerifying ? 'Vérification…' : 'Vérifier et activer',
          expanded: true,
          onPressed: _canSubmit ? onSubmit : null,
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        FrostedButton.text(
          label: 'Obtenir une clé sur ${provider.consoleLabel}',
          icon: Symbols.open_in_new_rounded,
          expanded: true,
          onPressed: isVerifying ? null : onOpenConsole,
        ),
      ],
    );
  }
}

class _ModelPicker extends ConsumerWidget {
  const _ModelPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AiProvider provider = ref.watch(selectedAiProviderProvider);
    final AiModel selected = ref.watch(selectedAiModelProvider);

    return FrostedListSection(
      label: 'Modèle',
      tiles: [
        for (final AiModel model in AiModel.forProvider(provider))
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
    );
  }

  Future<void> _select(WidgetRef ref, AiModel model) async {
    await ref.read(selectedAiModelProvider.notifier).select(model);
    ref.invalidate(quickAddEngineProvider);
    ref.invalidate(cloudReceiptReaderProvider);
  }
}
