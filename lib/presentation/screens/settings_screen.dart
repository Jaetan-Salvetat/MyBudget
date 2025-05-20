import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/core/controllers/theme_controller.dart';
import 'package:mybudget/core/controllers/data_controller.dart';
import 'package:mybudget/core/controllers/settings_controller.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';
import 'package:mybudget/presentation/widgets/settings/categories_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/dialog_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/theme_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/expense_calculation_bottom_sheet.dart';
import 'package:mybudget/presentation/screens/help_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  final bool isNested;
  final String fabTag;

  const SettingsScreen({
    this.isNested = false,
    this.fabTag = 'settings_fab',
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _themeController = Get.find<ThemeController>();
  final _dataController = Get.put(DataController());
  final _settingsController = Get.put(SettingsController());
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  // Fonction commentée pour migration Isar
  /*
  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return DialogBottomSheet.showConfirmation(
      context: context,
      title: 'Déconnexion',
      message: 'Voulez-vous vraiment vous déconnecter ?',
      cancelLabel: 'Annuler',
      confirmLabel: 'Déconnexion',
      onConfirm: () => Get.find<AuthController>().logout(),
    );
  }
  */

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Commenté pour migration Isar
    // final authController = Get.find<AuthController>();

    final content = ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 130, bottom: 16, left: 16, right: 16),
      children: [
        // Section Compte commentée pour migration Isar
        /*
        SettingsSection(
          title: 'Compte',
          children: [
            if (isUserConnected)
              SettingsTile(
                title: 'Déconnexion',
                subtitle:
                    'Connecté en tant que ${authController.user.value?.email ?? ""}',
                leading: const Icon(Icons.logout),
                onTap: () => _showLogoutConfirmationDialog(context),
              )
            else
              SettingsTile(
                title: 'Connexion / Inscription',
                subtitle: 'Connectez-vous pour synchroniser vos données',
                leading: const Icon(Icons.login),
                onTap: () => Get.toNamed('/login'),
              ),
          ],
        ),
        */
        SettingsSection(
          title: 'Apparence',
          children: [
            SettingsTile(
              title: 'Thème',
              subtitle: _getThemeNameFromMode(_themeController.themeMode),
              leading: const Icon(Icons.brightness_6),
              onTap: () {
                _showThemeSelectionDialog(context, _themeController.themeMode);
              },
            ),
          ],
        ),
        SettingsSection(
          title: 'Calculs financiers',
          children: [
            Obx(() {
              return SettingsTile(
                title: 'Calcul des dépenses annuelles',
                subtitle: _getAnnualExpenseCalculationModeName(
                  _settingsController.annualExpenseCalculationMode.value,
                ),
                leading: const Icon(Icons.calculate),
                onTap: () {
                  _showExpenseCalculationModeDialog(
                    context,
                    _settingsController.annualExpenseCalculationMode.value,
                  );
                },
              );
            }),
          ],
        ),
        SettingsSection(
          title: 'Catégories',
          children: [
            SettingsTile(
              title: 'Gérer les catégories',
              subtitle: 'Ajouter, modifier ou supprimer des catégories',
              leading: const Icon(Icons.category),
              onTap: () => CategoriesBottomSheet.show(context: context),
            ),
          ],
        ),
        SettingsSection(
          title: 'Données',
          children: [
            SettingsTile(
              title: 'Exporter mes données',
              subtitle: 'Sauvegardez vos données financières',
              leading: const Icon(Icons.upload_file),
              onTap: () => _exportUserData(context),
            ),
            SettingsTile(
              title: 'Importer mes données',
              subtitle: 'Restaurez vos données depuis une sauvegarde',
              leading: const Icon(Icons.download),
              onTap: () => _importUserData(context),
            ),
            SettingsTile(
              title: 'Supprimer toutes mes données',
              subtitle: 'Cette action est irréversible',
              leading: const Icon(Icons.delete_forever),
              onTap: () => _showDeleteDataConfirmationDialog(context),
            ),
          ],
        ),
        SettingsSection(
          title: 'Aide et informations',
          children: [
            SettingsTile(
              title: 'Guide d\'utilisation',
              subtitle: 'Consultez l\'aide et les explications',
              leading: const Icon(Icons.help_outline),
              onTap: () => Get.to(() => const HelpScreen()),
            ),
          ],
        ),
        SettingsSection(
          title: 'À propos',
          children: [
            /*SettingsTile(
              title: 'Politique de confidentialité',
              subtitle: 'Consultez notre politique de confidentialité',
              leading: const Icon(Icons.policy),
              onTap: () => Get.to(() => const PrivacyPolicyScreen()),
            ),*/
            SettingsTile(
              title: 'Version',
              subtitle:
                  packageInfo != null
                      ? '${packageInfo!.version} (${packageInfo!.buildNumber})'
                      : 'Chargement...',
              leading: const Icon(Icons.info_outline),
              onTap: null,
            ),
          ],
        ),
      ],
    );

    if (widget.isNested) {
      return content;
    }

    return AppScaffold(title: 'Paramètres', child: content);
  }

  String _getThemeNameFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Automatique';
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
    }
  }

  String _getAnnualExpenseCalculationModeName(
    AnnualExpenseCalculationMode mode,
  ) {
    switch (mode) {
      case AnnualExpenseCalculationMode.monthlyAmortized:
        return 'Amortissement mensuel';
      case AnnualExpenseCalculationMode.dateBasedOnly:
        return 'Mois spécifique uniquement';
    }
  }

  Future<void> _exportUserData(BuildContext context) async {
    await _dataController.exportUserData(context);
  }

  Future<void> _importUserData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.single.path;
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chemin du fichier invalide')),
        );
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fichier introuvable')));
        return;
      }

      _showImportConfirmationDialog(context, file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
      );
    }
  }

  Future<void> _showThemeSelectionDialog(
    BuildContext context,
    ThemeMode currentMode,
  ) async {
    return ThemeBottomSheet.show(
      context: context,
      currentMode: currentMode,
      onThemeSelected: (ThemeMode mode) {
        _themeController.changeTheme(mode);
        setState(() {});
      },
    );
  }

  Future<void> _showExpenseCalculationModeDialog(
    BuildContext context,
    AnnualExpenseCalculationMode currentMode,
  ) async {
    return ExpenseCalculationBottomSheet.show(
      context: context,
      currentMode: currentMode,
      onModeSelected: (AnnualExpenseCalculationMode mode) {
        _settingsController.setAnnualExpenseCalculationMode(mode);
      },
    );
  }

  void _showImportConfirmationDialog(BuildContext context, File file) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Importer des données'),
            content: const Text(
              'Voulez-vous importer ces données ? Cette action remplacera toutes vos données actuelles.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _dataController.importUserData(context, file);
                },
                child: const Text('Importer'),
              ),
            ],
          ),
    );
  }

  Future<void> _showDeleteDataConfirmationDialog(BuildContext context) async {
    return DialogBottomSheet.showConfirmation(
      context: context,
      title: 'Supprimer toutes les données',
      message:
          'Cette action supprimera toutes vos transactions et tous vos comptes. Cette action est irréversible.',
      confirmLabel: 'Supprimer',
      cancelLabel: 'Annuler',
      onConfirm: () => _dataController.deleteAllUserData(context),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leading;
  final VoidCallback? onTap;

  const SettingsTile({
    required this.title,
    this.subtitle,
    required this.leading,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: leading),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
