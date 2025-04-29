import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/presentation/providers/account_provider.dart';
import 'package:mybudget/presentation/providers/auth_provider.dart';
import 'package:mybudget/presentation/providers/expense_provider.dart';
import 'package:mybudget/presentation/providers/revenue_provider.dart';
import 'package:mybudget/presentation/providers/theme_provider.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';
import 'package:mybudget/presentation/widgets/settings/category_list.dart';
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
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [Text('Voulez-vous vraiment vous déconnecter ?')],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
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

    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(title: const Text('Paramètres')),
        body: ListView(
          padding: const EdgeInsets.all(16),
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
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CategoryList(),
                      ),
                    );
                  },
                ),
              ],
            ),
            SettingsSection(
              title: 'Données',
              children: [
                SettingsTile(
                  title: 'Effacer toutes les données',
                  subtitle:
                      'Supprimer définitivement toutes les données de l\'application',
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choisir un thème'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Clair'),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Sombre'),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Système'),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDataConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Effacer toutes les données'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer définitivement toutes les données ? Cette action est irréversible.',
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
                final accountNotifier = ref.read(
                  accountNotifierProvider.notifier,
                );
                final expenseNotifier = ref.read(
                  expenseNotifierProvider.notifier,
                );
                final revenueNotifier = ref.read(
                  revenueNotifierProvider.notifier,
                );

                // Supprimer la fonction _deleteAllData dupliquée

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
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Toutes les données ont été supprimées'),
                    ),
                  );
                }
              },
              child: const Text('Supprimer'),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: SizedBox(width: 32, height: 32, child: Center(child: leading)),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
