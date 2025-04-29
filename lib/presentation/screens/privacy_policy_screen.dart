import 'package:flutter/material.dart';
import 'package:mybudget/presentation/widgets/auth/auth_background.dart';
import 'package:mybudget/presentation/widgets/auth/auth_button.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      title: 'Politique de confidentialité',
      onBackPressed: () => Navigator.pop(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Politique de confidentialité',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dernière mise à jour : 29 avril 2025',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Introduction'),
                  _buildParagraph(
                    'Cette politique de confidentialité explique comment MyBudget collecte, utilise et protège vos données personnelles lorsque vous utilisez notre application. Nous nous engageons à protéger votre vie privée conformément au Règlement Général sur la Protection des Données (RGPD).',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Données collectées'),
                  _buildParagraph(
                    'Nous collectons uniquement les données nécessaires au fonctionnement de l\'application :',
                  ),
                  _buildBulletPoint('Données d\'identification (nom, email) pour la création et la gestion de votre compte'),
                  _buildBulletPoint('Données financières que vous saisissez dans l\'application (comptes, dépenses, revenus)'),
                  _buildBulletPoint('Préférences de thème et paramètres de l\'application'),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Utilisation des données'),
                  _buildParagraph(
                    'Nous utilisons vos données exclusivement pour :',
                  ),
                  _buildBulletPoint('Vous permettre de gérer vos finances personnelles'),
                  _buildBulletPoint('Améliorer votre expérience utilisateur'),
                  _buildBulletPoint('Vous authentifier et sécuriser votre compte'),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Stockage et sécurité'),
                  _buildParagraph(
                    'Vos données sont stockées localement sur votre appareil. Si vous activez la synchronisation, elles seront stockées de manière sécurisée sur nos serveurs avec chiffrement. Nous ne partageons jamais vos données avec des tiers sans votre consentement explicite.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Vos droits'),
                  _buildParagraph(
                    'Conformément au RGPD, vous disposez des droits suivants :',
                  ),
                  _buildBulletPoint('Droit d\'accès à vos données personnelles'),
                  _buildBulletPoint('Droit de rectification de vos données'),
                  _buildBulletPoint('Droit à l\'effacement (\'droit à l\'oubli\')'),
                  _buildBulletPoint('Droit à la limitation du traitement'),
                  _buildBulletPoint('Droit à la portabilité des données'),
                  _buildBulletPoint('Droit d\'opposition au traitement'),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Exercer vos droits'),
                  _buildParagraph(
                    'Vous pouvez exercer vos droits directement depuis l\'application dans la section Paramètres > Données personnelles ou en nous contactant à gaetansalvi08@gmail.com.',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Modifications'),
                  _buildParagraph(
                    'Nous pouvons occasionnellement mettre à jour cette politique de confidentialité. Vous serez notifié de tout changement significatif.',
                  ),
                  const SizedBox(height: 32),
                  AuthButton(
                    label: 'J\'ai compris',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(content),
    );
  }

  Widget _buildBulletPoint(String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(content)),
        ],
      ),
    );
  }
}
