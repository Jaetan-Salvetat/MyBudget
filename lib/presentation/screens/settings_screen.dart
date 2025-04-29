import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/presentation/providers/account_provider.dart';
import 'package:mybudget/presentation/providers/auth_provider.dart';
import 'package:mybudget/presentation/providers/expense_provider.dart';
import 'package:mybudget/presentation/providers/revenue_provider.dart';
import 'package:mybudget/presentation/providers/theme_provider.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';
import 'package:mybudget/presentation/widgets/settings/categories_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/data_privacy_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/dialog_bottom_sheet.dart';
import 'package:mybudget/presentation/widgets/settings/theme_bottom_sheet.dart';
import 'package:mybudget/presentation/screens/privacy_policy_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return DialogBottomSheet.showConfirmation(
      context: context,
      title: 'Déconnexion',
      message: 'Voulez-vous vraiment vous déconnecter ?',
      cancelLabel: 'Annuler',
      confirmLabel: 'Déconnexion',
      onConfirm: () => ref.read(authProvider.notifier).logout(),
    );
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final isUserConnected = authState.value != null && authState.value!.isAuthenticated;

    return AppScaffold(
      title: 'Paramètres',
      child: ListView(
        padding: const EdgeInsets.only(
          top: 130,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        children: [
          SettingsSection(
            title: 'Compte',
            children: [
              if (authState.value != null && authState.value!.isAuthenticated)
                SettingsTile(
                  title: 'Déconnexion',
                  subtitle:
                      'Connecté en tant que ${authState.value?.email ?? ""}',
                  leading: const Icon(Icons.logout),
                  onTap: () => _showLogoutConfirmationDialog(context),
                )
              else
                SettingsTile(
                  title: 'Connexion / Inscription',
                  subtitle: 'Connectez-vous pour synchroniser vos données',
                  leading: const Icon(Icons.login),
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),
            ],
          ),
          SettingsSection(
            title: 'Apparence',
            children: [
              SettingsTile(
                title: 'Thème',
                subtitle: _getThemeNameFromMode(themeMode),
                leading: const Icon(Icons.brightness_6),
                onTap: () {
                  _showThemeSelectionDialog(context, themeMode);
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
          if (isUserConnected)
            SettingsSection(
              title: 'Données personnelles',
              children: [
                SettingsTile(
                  title: 'Confidentialité et RGPD',
                  subtitle: 'Gérer vos données personnelles',
                  leading: const Icon(Icons.privacy_tip),
                  onTap: () => DataPrivacyBottomSheet.show(context: context),
                ),
                SettingsTile(
                  title: 'Politique de confidentialité',
                  subtitle: 'Consulter notre politique de confidentialité',
                  leading: const Icon(Icons.policy),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                  ),
                ),
              ],
            ),
          SettingsSection(
            title: 'Données',
            children: [
              SettingsTile(
                title: 'Effacer les données',
                subtitle: 'Supprimer définitivement toutes les données de l\'application',
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                onTap: () {
                  _showDeleteDataConfirmationDialog(context);
                },
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
              ),
              SettingsTile(
                title: 'Développeur',
                subtitle: 'Jaetan Salvetat',
                leading: const Icon(Icons.code),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getThemeNameFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }

  void _showThemeSelectionDialog(BuildContext context, ThemeMode currentMode) {
    ThemeBottomSheet.show(
      context: context,
      currentMode: currentMode,
      onThemeSelected: (ThemeMode value) {
        ref.read(themeProvider.notifier).setTheme(value);
      },
    );
  }

  void _showDeleteDataConfirmationDialog(BuildContext context) {
    DialogBottomSheet.showConfirmation(
      context: context,
      title: 'Effacer toutes les données',
      message:
          'Êtes-vous sûr de vouloir supprimer définitivement toutes les données ? Cette action est irréversible.',
      cancelLabel: 'Annuler',
      confirmLabel: 'Supprimer',
      isDestructive: true,
      onConfirm: () async {
        final accountNotifier = ref.read(accountNotifierProvider.notifier);
        final expenseNotifier = ref.read(expenseNotifierProvider.notifier);
        final revenueNotifier = ref.read(revenueNotifierProvider.notifier);

        final accountsList = ref.read(accountNotifierProvider);
        final expensesList = ref.read(expenseNotifierProvider);
        final revenuesList = ref.read(revenueNotifierProvider);

        // Supprimer les transactions d'abord
        for (final expense in expensesList) {
          expenseNotifier.deleteExpense(expense.id);
        }

        for (final revenue in revenuesList) {
          revenueNotifier.deleteRevenue(revenue.id);
        }

        // Supprimer les comptes ensuite
        for (final account in accountsList) {
          accountNotifier.deleteAccount(account.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Toutes les données ont été supprimées'),
            ),
          );
        }
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
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
