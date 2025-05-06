import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:mybudget/core/controllers/auth_controller.dart'; // Commenté pour migration Isar
import 'package:mybudget/core/controllers/account_controller.dart';
import 'package:mybudget/core/controllers/expense_controller.dart';
import 'package:mybudget/core/controllers/revenue_controller.dart';
import 'package:mybudget/core/controllers/theme_controller.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';
import 'package:mybudget/presentation/widgets/settings/categories_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/data_privacy_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/dialog_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/theme_bottom_sheet.dart';
import 'package:mybudget/presentation/screens/privacy_policy_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? packageInfo;
  late ThemeController themeController;

  @override
  void initState() {
    super.initState();
    themeController = Get.find<ThemeController>();
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

    return AppScaffold(
      title: 'Paramètres',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 130,
          bottom: 16,
          left: 16,
          right: 16,
        ),
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
                subtitle: _getThemeNameFromMode(themeController.themeMode),
                leading: const Icon(Icons.brightness_6),
                onTap: () {
                  _showThemeSelectionDialog(context, themeController.themeMode);
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
                title: 'Confidentialité et données',
                subtitle: 'Exportez ou réinitialisez vos données',
                leading: const Icon(Icons.security),
                onTap: () => DataPrivacyBottomSheet.show(context: context),
              ),
              SettingsTile(
                title: 'Tout supprimer',
                subtitle:
                    'Supprimer toutes les transactions et tous les comptes',
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                onTap: () => _showDeleteDataConfirmationDialog(context),
              ),
            ],
          ),
          SettingsSection(
            title: 'À propos',
            children: [
              SettingsTile(
                title: 'Politique de confidentialité',
                subtitle: 'Consultez notre politique de confidentialité',
                leading: const Icon(Icons.policy),
                onTap: () => Get.to(() => const PrivacyPolicyScreen()),
              ),
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
        return 'Système';
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
    }
  }

  Future<void> _showThemeSelectionDialog(
    BuildContext context,
    ThemeMode currentMode,
  ) async {
    ThemeBottomSheet.show(
      context: context,
      currentMode: currentMode,
      onThemeSelected: (ThemeMode newMode) {
        themeController.changeTheme(newMode);
      },
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
      onConfirm: () async {
        final accountController = Get.find<AccountController>();
        final expenseController = Get.find<ExpenseController>();
        final revenueController = Get.find<RevenueController>();

        final accountsList = accountController.accounts;
        final expensesList = expenseController.expenses;
        final revenuesList = revenueController.revenues;

        // Supprimer les transactions d'abord
        for (final expense in expensesList) {
          expenseController.deleteExpense(expense.id);
        }

        for (final revenue in revenuesList) {
          revenueController.deleteRevenue(revenue.id);
        }

        // Supprimer les comptes ensuite
        for (final account in accountsList) {
          accountController.deleteAccount(account.id);
        }

        Get.snackbar(
          'Suppression terminée',
          'Toutes les données ont été supprimées',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
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
