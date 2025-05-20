import 'package:flutter/material.dart';
import 'package:mybudget/presentation/widgets/common/app_button.dart';

class EmptyDashboardState extends StatelessWidget {
  final VoidCallback onSetupPressed;

  const EmptyDashboardState({
    required this.onSetupPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Commencez à gérer vos finances',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ajoutez vos comptes et transactions pour voir un résumé de votre situation financière',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Ajouter un compte',
              icon: Icons.add,
              onPressed: onSetupPressed,
            ),
          ],
        ),
      ),
    );
  }
}
