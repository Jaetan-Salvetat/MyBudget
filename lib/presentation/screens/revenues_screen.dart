import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/common/app_scaffold.dart';
import '../providers/revenue_provider.dart';
import '../providers/account_provider.dart';
import '../../domain/entities/revenue.dart';
import '../../domain/entities/account.dart';
import '../widgets/revenues/revenue_bottom_sheet.dart';

class RevenuesScreen extends ConsumerWidget {
  const RevenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Revenus',
      useNestedAppBar: false,
      child: const RevenuesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRevenueBottomSheet(context, ref),
        tooltip: 'Ajouter un revenu',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showAddRevenueBottomSheet(BuildContext context, WidgetRef ref) {
    RevenueBottomSheet.show(
      context: context,
      accounts: ref.read(accountNotifierProvider),
      onSubmit: (revenue) {
        ref.read(revenueNotifierProvider.notifier).addRevenue(revenue);
        Navigator.of(context).pop();
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}

class RevenuesList extends ConsumerWidget {
  const RevenuesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenues = ref.watch(revenueNotifierProvider);
    final accounts = ref.watch(accountNotifierProvider);

    if (revenues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun revenu enregistré',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                RevenueBottomSheet.show(
                  context: context,
                  accounts: ref.read(accountNotifierProvider),
                  onSubmit: (revenue) {
                    ref
                        .read(revenueNotifierProvider.notifier)
                        .addRevenue(revenue);
                    Navigator.of(context).pop();
                  },
                  onCancel: () => Navigator.of(context).pop(),
                );
              },
              child: const Text('Ajouter un revenu'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 130, bottom: 16, left: 16, right: 16),
      itemCount: revenues.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final revenue = revenues[index];
        // Récupérer le compte associé au revenu
        // Recherche du compte associé au revenu
        Account? account;
        if (accounts.isNotEmpty) {
          try {
            account = accounts.firstWhere((a) => a.id == revenue.accountId);
          } catch (_) {
            // Si aucun compte correspondant n'est trouvé, on utilise le premier
            account = accounts.first;
          }
        }

        return RevenueCard(
          revenue: revenue,
          accountName: account?.name ?? 'Compte inconnu',
          onDelete: () {
            ref
                .read(revenueNotifierProvider.notifier)
                .deleteRevenue(revenue.id);
          },
          onEdit: () {
            RevenueBottomSheet.show(
              context: context,
              accounts: ref.read(accountNotifierProvider),
              revenue: revenue,
              onSubmit: (updatedRevenue) {
                ref
                    .read(revenueNotifierProvider.notifier)
                    .updateRevenue(updatedRevenue);
                Navigator.of(context).pop();
              },
              onCancel: () => Navigator.of(context).pop(),
            );
          },
        );
      },
    );
  }
}

class RevenueCard extends StatelessWidget {
  final Revenue revenue;
  final String accountName;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const RevenueCard({
    required this.revenue,
    required this.accountName,
    required this.onDelete,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.payments,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          revenue.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          accountName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${revenue.amount.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (revenue.isRegular)
                    Chip(
                      label: const Text('Régulier'),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  Chip(
                    label: Text(
                      '${revenue.date.day}/${revenue.date.month}/${revenue.date.year}',
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: Text(
                                'Voulez-vous vraiment supprimer ${revenue.name} ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: () {
                                    onDelete();
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                  IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
