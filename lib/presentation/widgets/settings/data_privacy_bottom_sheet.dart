import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/presentation/providers/account_provider.dart';
import 'package:mybudget/presentation/providers/auth_provider.dart';
import 'package:mybudget/presentation/providers/expense_provider.dart';
import 'package:mybudget/presentation/providers/privacy_provider.dart';
import 'package:mybudget/presentation/providers/revenue_provider.dart';
import 'package:mybudget/presentation/screens/privacy_policy_screen.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/dialog_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataPrivacyBottomSheet extends ConsumerStatefulWidget {
  const DataPrivacyBottomSheet({super.key});

  static Future<void> show({
    required BuildContext context,
  }) {
    return AppModalBottomSheet.show(
      context: context,
      title: 'Confidentialité des données',
      content: const DataPrivacyBottomSheet(),
      actions: const [],
      isScrollable: true,
    );
  }

  @override
  ConsumerState<DataPrivacyBottomSheet> createState() => _DataPrivacyBottomSheetState();
}

class _DataPrivacyBottomSheetState extends ConsumerState<DataPrivacyBottomSheet> {
  bool _isLoading = false;
  String? _lastExportPath;

  Future<void> _exportUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authProvider).value;
      final userData = <String, dynamic>{
        'user': user != null ? {
          'id': user.id,
          'email': user.email,
          'name': user.name,
          'isAuthenticated': user.isAuthenticated,
        } : null,
        'accounts': ref.read(accountNotifierProvider).map((acc) => acc.toJson()).toList(),
        'expenses': ref.read(expenseNotifierProvider).map((exp) => exp.toJson()).toList(),
        'revenues': ref.read(revenueNotifierProvider).map((rev) => rev.toJson()).toList(),
        'export_date': DateTime.now().toIso8601String(),
      };

      final jsonData = jsonEncode(userData);
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/mybudget_data_export.json';
      final file = File(filePath);
      await file.writeAsString(jsonData);
      
      setState(() {
        _lastExportPath = filePath;
        _isLoading = false;
      });

      if (mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'MyBudget - Vos données personnelles',
          text: 'Export de vos données personnelles MyBudget conformément au RGPD.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(context, 'Gestion de vos données personnelles'),
        const SizedBox(height: 8),
        _buildInfoCard(
          context,
          'En vertu du Règlement Général sur la Protection des Données (RGPD), vous disposez de droits spécifiques concernant vos données personnelles. Utilisez les options ci-dessous pour les exercer.',
        ),
        const SizedBox(height: 24),
        _buildActionTile(
          context,
          title: 'Politique de confidentialité',
          subtitle: 'Consultez notre politique de confidentialité',
          icon: Icons.policy,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          context,
          title: 'Exporter mes données',
          subtitle: 'Téléchargez une copie de toutes vos données',
          icon: Icons.download,
          isLoading: _isLoading,
          onTap: _exportUserData,
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          context,
          title: 'Supprimer mon compte',
          subtitle: 'Effacer définitivement votre compte et vos données',
          icon: Icons.delete_forever,
          isDestructive: true,
          onTap: () {
            DialogBottomSheet.showConfirmation(
              context: context,
              title: 'Supprimer mon compte',
              message: 'Êtes-vous sûr de vouloir supprimer définitivement votre compte et toutes vos données ? Cette action est irréversible et conforme à votre droit à l\'oubli (RGPD).',
              cancelLabel: 'Annuler',
              confirmLabel: 'Supprimer définitivement',
              isDestructive: true,
              onConfirm: () async {
                try {
                  final accountNotifier = ref.read(
                    accountNotifierProvider.notifier,
                  );
                  final expenseNotifier = ref.read(
                    expenseNotifierProvider.notifier,
                  );
                  final revenueNotifier = ref.read(
                    revenueNotifierProvider.notifier,
                  );

                  final accountsList = ref.read(accountNotifierProvider);
                  final expensesList = ref.read(expenseNotifierProvider);
                  final revenuesList = ref.read(revenueNotifierProvider);

                  // Supprimer les transactions
                  for (final expense in expensesList) {
                    expenseNotifier.deleteExpense(expense.id);
                  }

                  for (final revenue in revenuesList) {
                    revenueNotifier.deleteRevenue(revenue.id);
                  }

                  // Supprimer les comptes
                  for (final account in accountsList) {
                    accountNotifier.deleteAccount(account.id);
                  }

                  // Déconnecter l'utilisateur
                  await ref.read(authProvider.notifier).logout();

                  // Afficher confirmation
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Votre compte et vos données ont été supprimés'),
                      ),
                    );
                    
                    // Retourner à l'écran d'accueil
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
              },
            );
          },
        ),
        const SizedBox(height: 24),
        _buildConsentSettings(context),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        content,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(
                        icon,
                        color: color,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDestructive
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentSettings(BuildContext context) {
    final privacySettings = ref.watch(privacySettingsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Préférences de confidentialité'),
        const SizedBox(height: 16),
        privacySettings.when(
          data: (settings) {
            if (settings == null) {
              return const Text('Aucune préférence configurée');
            }
            return Column(
              children: [
                ListTile(
                  title: const Text('Communications marketing'),
                  subtitle: const Text('Recevoir des informations sur nos produits'),
                  trailing: Switch(
                    value: settings.marketingConsent,
                    onChanged: (value) {
                      ref.read(privacySettingsProvider.notifier).updateMarketingConsent(value);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Politique de confidentialité acceptée'),
                  subtitle: Text('Le ${settings.consentDate.day}/${settings.consentDate.month}/${settings.consentDate.year}'),
                  trailing: Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Erreur: $error'),
        ),
      ],
    );
  }
}
