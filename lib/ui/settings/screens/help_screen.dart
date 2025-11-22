import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide et Guide')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            context,
            'Bienvenue dans MyBudget',
            'MyBudget vous aide à gérer vos finances personnelles simplement et efficacement.',
            Icons.waving_hand,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Dashboard',
            'Visualisez votre solde actuel, vos dépenses par catégorie et vos paiements à venir en un coup d\'œil.',
            Icons.dashboard,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Comptes',
            'Gérez vos différents comptes bancaires. Vous pouvez voir le solde de chaque compte et les transactions associées.',
            Icons.account_balance,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Dépenses et Revenus',
            'Ajoutez vos transactions quotidiennes. Vous pouvez spécifier si elles sont récurrentes (mensuelles, annuelles) pour qu\'elles s\'ajoutent automatiquement.',
            Icons.swap_horiz,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Emprunts',
            'Suivez vos prêts en cours. L\'application calcule automatiquement le montant restant et la progression du remboursement.',
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Paramètres',
            'Personnalisez l\'application (thème sombre/clair), gérez vos catégories, et sauvegardez vos données.',
            Icons.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
