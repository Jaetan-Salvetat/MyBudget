import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mybudget/core/enums/annual_expense_calculation_mode.dart';
import 'package:mybudget/ui/settings/settings_viewmodel.dart';
import 'package:mybudget/ui/settings/data_viewmodel.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/widgets/categories_bottom_sheet.dart';
import 'package:mybudget/ui/settings/widgets/theme_bottom_sheet.dart';
import 'package:mybudget/ui/settings/widgets/expense_calculation_bottom_sheet.dart';
import 'package:mybudget/ui/settings/screens/help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsVM = Provider.of<SettingsViewModel>(context);
    final dataVM = Provider.of<DataViewModel>(context);

    return FrostedScaffold(
      appBar: FrostedAppBar(
        title: 'Paramètres',
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 130,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        children: [
          SettingsSection(
            title: 'Apparence',
            children: [
              SettingsTile(
                title: 'Thème',
                subtitle: _getThemeNameFromMode(settingsVM.themeMode),
                leading: const Icon(Icons.brightness_6),
                onTap: () {
                  _showThemeSelectionDialog(context, settingsVM.themeMode);
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Calculs financiers',
            children: [
              SettingsTile(
                title: 'Calcul des dépenses annuelles',
                subtitle: _getAnnualExpenseCalculationModeName(
                  settingsVM.annualExpenseCalculationMode,
                ),
                leading: const Icon(Icons.calculate),
                onTap: () {
                  _showExpenseCalculationModeDialog(
                    context,
                    settingsVM.annualExpenseCalculationMode,
                  );
                },
              ),
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
                onTap: () => _exportUserData(context, dataVM),
              ),
              SettingsTile(
                title: 'Importer mes données',
                subtitle: 'Restaurez vos données depuis une sauvegarde',
                leading: const Icon(Icons.download),
                onTap: () => _importUserData(context, dataVM),
              ),
              SettingsTile(
                title: 'Supprimer toutes mes données',
                subtitle: 'Cette action est irréversible',
                leading: const Icon(Icons.delete_forever),
                onTap: () => _showDeleteDataConfirmationDialog(context, dataVM),
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
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpScreen(),
                      ),
                    ),
              ),
            ],
          ),
          SettingsSection(
            title: 'À propos',
            children: [
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
      ),
    );
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

  Future<void> _exportUserData(
    BuildContext context,
    DataViewModel dataVM,
  ) async {
    await dataVM.exportUserData(context);
  }

  Future<void> _importUserData(
    BuildContext context,
    DataViewModel dataVM,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.single.path;
      if (path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chemin du fichier invalide')),
          );
        }
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Fichier introuvable')));
        }
        return;
      }

      if (mounted) {
        _showImportConfirmationDialog(context, file, dataVM);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
        );
      }
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
        final settingsVM = Provider.of<SettingsViewModel>(
          context,
          listen: false,
        );
        settingsVM.updateThemeMode(mode);
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
        final settingsVM = Provider.of<SettingsViewModel>(
          context,
          listen: false,
        );
        settingsVM.updateAnnualExpenseCalculationMode(mode);
      },
    );
  }

  void _showImportConfirmationDialog(
    BuildContext context,
    File file,
    DataViewModel dataVM,
  ) {
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
                  Navigator.of(context).pop(); // Ferme la confirmation
                  _showImportProgressDialog(context, file, dataVM);
                },
                child: const Text('Importer'),
              ),
            ],
          ),
    );
  }

  void _showImportProgressDialog(
    BuildContext context,
    File file,
    DataViewModel dataVM,
  ) {
    dataVM.importUserData(context, file);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Consumer<DataViewModel>(
            builder: (context, vm, child) {
              if (vm.isImporting) {
                return AlertDialog(
                  title: const Text('Importation en cours'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Veuillez ne pas quitter l\'application pendant l\'importation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(value: vm.importProgress),
                      const SizedBox(height: 10),
                      Text(
                        vm.importStatus,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              if (vm.error.isNotEmpty) {
                return AlertDialog(
                  title: const Text('Erreur d\'importation'),
                  content: Text(vm.error),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Fermer'),
                    ),
                  ],
                );
              }

              return AlertDialog(
                title: const Text('Importation réussie'),
                content: const Text(
                  'Les données ont été importées avec succès.\n\n'
                  'Pour finaliser l\'opération et éviter tout problème d\'affichage, '
                  'l\'application va se fermer. Veuillez la relancer manuellement.',
                ),
                actions: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => exit(0), // Force quit l'app
                    child: const Text('Quitter l\'application'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showDeleteDataConfirmationDialog(
    BuildContext context,
    DataViewModel dataVM,
  ) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer toutes les données'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer toutes vos données ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await dataVM.deleteAllUserData(context);
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
