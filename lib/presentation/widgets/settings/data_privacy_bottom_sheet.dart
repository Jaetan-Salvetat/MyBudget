import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/controllers/auth_controller.dart';
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/privacy_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/presentation/screens/privacy_policy_screen.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/dialog_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataPrivacyBottomSheet extends StatefulWidget {
  const DataPrivacyBottomSheet({super.key});

  static Future<void> show({required BuildContext context}) {
    return AppModalBottomSheet.show(
      context: context,
      title: 'Confidentialité des données',
      content: const DataPrivacyBottomSheet(),
      actions: const [],
      isScrollable: true,
    );
  }

  @override
  State<DataPrivacyBottomSheet> createState() => _DataPrivacyBottomSheetState();
}

class _DataPrivacyBottomSheetState extends State<DataPrivacyBottomSheet> {
  bool _isLoading = false;
  String? _lastExportPath;

  Future<void> _exportUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authController = Get.find<AuthController>();
      final accountController = Get.find<AccountController>();
      final expenseController = Get.find<ExpenseController>();
      final revenueController = Get.find<RevenueController>();

      final user = authController.user.value;
      final userData = <String, dynamic>{
        'user':
            user != null
                ? {
                  'id': user.id,
                  'email': user.email,
                  'name': user.name,
                  'isAuthenticated': user.isAuthenticated,
                }
                : null,
        'accounts':
            accountController.accounts.map((acc) => acc.toJson()).toList(),
        'expenses':
            expenseController.expenses.map((exp) => exp.toJson()).toList(),
        'revenues':
            revenueController.revenues.map((rev) => rev.toJson()).toList(),
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
          text:
              'Export de vos données personnelles MyBudget conformément au RGPD.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'export: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final privacyController = Get.find<PrivacyController>();

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
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          context,
          title: 'Exporter mes données',
          subtitle: 'Télécharger une copie de toutes vos données',
          icon: Icons.download,
          onTap: _exportUserData,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        _buildActionTile(
          context,
          title: 'Demander la suppression',
          subtitle: 'Supprimer définitivement votre compte et vos données',
          icon: Icons.delete_forever,
          isDestructive: true,
          onTap: () {
            DialogBottomSheet.showConfirmation(
              context: context,
              title: 'Demande de suppression',
              message:
                  'Cette action est irréversible. Votre compte et toutes vos données seront définitivement supprimés de nos serveurs.\n\nSouhaitez-vous continuer ?',
              cancelLabel: 'Annuler',
              confirmLabel: 'Confirmer la suppression',
              isDestructive: true,
              onConfirm: () {
                // Logique de suppression des données
                // À implémenter
                Get.back();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Votre demande de suppression a été enregistrée.',
                    ),
                  ),
                );
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
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
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    final color =
        isDestructive
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
                child:
                    isLoading
                        ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                        : Icon(icon, color: color),
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
                        color:
                            isDestructive
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
    final privacyController = Get.find<PrivacyController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Préférences de confidentialité'),
        const SizedBox(height: 16),
        Obx(() {
          final settings = privacyController.privacySettings.value;

          if (settings == null) {
            return const Text('Aucune préférence configurée');
          }

          return Column(
            children: [
              ListTile(
                title: const Text('Communications marketing'),
                subtitle: const Text(
                  'Recevoir des informations sur nos produits',
                ),
                trailing: Switch(
                  value: settings.marketingConsent,
                  onChanged: (value) {
                    privacyController.updateMarketingConsent(value);
                  },
                ),
              ),
              ListTile(
                title: const Text('Politique de confidentialité acceptée'),
                subtitle: Text(
                  'Le ${settings.consentDate.day}/${settings.consentDate.month}/${settings.consentDate.year}',
                ),
                trailing: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
