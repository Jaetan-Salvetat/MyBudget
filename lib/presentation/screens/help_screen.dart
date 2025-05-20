import 'package:flutter/material.dart';
import 'package:mybudget/presentation/widgets/common/app_scaffold.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Aide',
      useNestedAppBar: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          const SizedBox(height: 100),
          _buildHelpSection(
            context: context,
            title: 'Calcul des dépenses annuelles',
            icon: Icons.calculate_outlined,
            items: [
              _HelpItem(
                title: 'Amorti mensuel',
                description:
                    'Les dépenses annuelles sont divisées par 12 et réparties équitablement sur tous les mois de l\'année.',
              ),
              _HelpItem(
                title: 'Par date uniquement',
                description:
                    'Les dépenses annuelles apparaissent uniquement dans le mois où elles sont dues, sans répartition sur l\'année.',
              ),
            ],
          ),
          _buildHelpSection(
            context: context,
            title: 'Gérer vos dépenses',
            icon: Icons.money_off_outlined,
            items: [
              _HelpItem(
                title: 'Ajouter une dépense',
                description:
                    'Utilisez le bouton + pour ajouter une nouvelle dépense. Vous pouvez spécifier si elle est mensuelle ou annuelle.',
              ),
              _HelpItem(
                title: 'Filtrer vos dépenses',
                description:
                    'Cliquez sur l\'icône de filtre pour organiser vos dépenses par catégorie, compte, montant ou date.',
              ),
              _HelpItem(
                title: 'Modifier ou supprimer',
                description:
                    'Appuyez sur une dépense existante pour l\'éditer, ou utilisez l\'option de suppression pour la retirer.',
              ),
            ],
          ),
          _buildHelpSection(
            context: context,
            title: 'Comptes et revenus',
            icon: Icons.account_balance_outlined,
            items: [
              _HelpItem(
                title: 'Comptes multiples',
                description:
                    'Créez différents comptes pour suivre vos finances selon vos besoins : compte courant, épargne, etc.',
              ),
              _HelpItem(
                title: 'Revenus',
                description:
                    'Enregistrez vos différentes sources de revenus pour obtenir une vue complète de votre situation financière.',
              ),
            ],
          ),
          _buildHelpSection(
            context: context,
            title: 'Tableau de bord',
            icon: Icons.dashboard_outlined,
            items: [
              _HelpItem(
                title: 'Vue d\'ensemble',
                description:
                    'Le tableau de bord vous présente un résumé de vos finances : solde, dépenses, revenus et prêts.',
              ),
              _HelpItem(
                title: 'Dépenses par catégorie',
                description:
                    'Visualisez la répartition de vos dépenses par catégorie pour identifier vos principaux postes de dépenses.',
              ),
              _HelpItem(
                title: 'Taux d\'épargne',
                description:
                    'Suivez votre capacité d\'épargne en pourcentage de vos revenus pour atteindre vos objectifs financiers.',
              ),
            ],
          ),
          _buildHelpSection(
            context: context,
            title: 'Paramètres',
            icon: Icons.settings_outlined,
            items: [
              _HelpItem(
                title: 'Apparence',
                description:
                    'Personnalisez l\'apparence de l\'application en choisissant entre le thème clair, sombre ou système.',
              ),
              _HelpItem(
                title: 'Importation/Exportation',
                description:
                    'Sauvegardez vos données ou importez-les depuis un fichier pour les transférer entre appareils.',
              ),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildHelpSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<_HelpItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: List.generate(items.length, (index) {
                final isLast = index == items.length - 1;
                return _buildHelpItemWidget(
                  context: context,
                  item: items[index],
                  isLastItem: isLast,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItemWidget({
    required BuildContext context,
    required _HelpItem item,
    required bool isLastItem,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLastItem
            ? null
            : Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem {
  final String title;
  final String description;

  const _HelpItem({
    required this.title,
    required this.description,
  });
}
