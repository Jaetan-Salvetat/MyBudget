import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/secure_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GeminiApiKeyBottomSheet extends StatefulWidget {
  final bool hasExistingKey;

  const GeminiApiKeyBottomSheet({
    required this.hasExistingKey,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required bool hasExistingKey,
  }) {
    return FrostedBottomSheet.show(
      context: context,
      title: 'Clé API Gemini',
      child: GeminiApiKeyBottomSheet(hasExistingKey: hasExistingKey),
    );
  }

  @override
  State<GeminiApiKeyBottomSheet> createState() =>
      _GeminiApiKeyBottomSheetState();
}

class _GeminiApiKeyBottomSheetState extends State<GeminiApiKeyBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isFormValid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateForm);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _controller.text.trim().isNotEmpty;
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _saveKey() async {
    setState(() => _isSaving = true);
    try {
      await SecureStorageService.setGeminiApiKey(_controller.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de la sauvegarde : $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteKey() async {
    try {
      await SecureStorageService.deleteGeminiApiKey();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de la suppression : $e',
        );
      }
    }
  }

  Future<void> _openApiKeyPage() async {
    await launchUrl(
      Uri.parse('https://aistudio.google.com/apikey'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            context,
            icon: Icons.info_outline,
            color: theme.colorScheme.primary,
            title: 'Comment obtenir une clé ?',
            children: [
              const Text(
                '1. Rendez-vous sur Google AI Studio\n'
                '2. Connectez-vous avec votre compte Google\n'
                '3. Cliquez sur "Créer une clé API"\n'
                '4. Copiez la clé générée',
              ),
              const SizedBox(height: 12),
              FrostedTextButton(
                onPressed: _openApiKeyPage,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 16),
                    SizedBox(width: 8),
                    Text('Ouvrir Google AI Studio'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            icon: Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            title: 'Important',
            children: [
              Text(
                'Votre clé est stockée de manière sécurisée sur votre appareil. '
                'Ne partagez jamais votre clé API avec qui que ce soit. '
                'L\'utilisation de l\'API Gemini est soumise aux conditions '
                'd\'utilisation de Google et peut engendrer des frais selon votre forfait.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FrostedTextField(
            controller: _controller,
            labelText: 'Clé API Gemini',
            hintText: 'AIza...',
            prefixIcon: const Icon(Icons.vpn_key_outlined),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.hasExistingKey)
                FrostedTextButton(
                  onPressed: _deleteKey,
                  child: Text(
                    'Supprimer ma clé',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              if (widget.hasExistingKey) const SizedBox(width: 16),
              FrostedFilledButton(
                onPressed: _isFormValid && !_isSaving ? _saveKey : null,
                child: Text(
                  widget.hasExistingKey ? 'Remplacer' : 'Enregistrer',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
