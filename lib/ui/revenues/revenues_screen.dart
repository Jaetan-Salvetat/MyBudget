import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/revenues/widgets/revenue_bottom_sheet.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_list.dart';

class RevenuesScreen extends StatelessWidget {
  final bool isNested;
  final String fabTag;

  const RevenuesScreen({
    this.isNested = false,
    this.fabTag = 'revenues_fab',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        const SizedBox(height: 100),
        Expanded(child: const RevenuesList()),
      ],
    );

    if (isNested) {
      return Stack(
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: FrostedFloatingActionButton(
              onPressed: () => _showAddRevenueBottomSheet(context),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return FrostedScaffold(
      appBar: const FrostedAppBar(title: 'Revenus'),
      floatingActionButton: FrostedFloatingActionButton(
        onPressed: () => _showAddRevenueBottomSheet(context),
        child: const Icon(Icons.add),
      ),
      child: content,
    );
  }

  void _showAddRevenueBottomSheet(BuildContext context) {
    final accountViewModel = Provider.of<AccountViewModel>(
      context,
      listen: false,
    );
    final revenueViewModel = Provider.of<RevenueViewModel>(
      context,
      listen: false,
    );

    if (accountViewModel.accounts.isEmpty) {
      FrostedDialog.show(
        context: context,
        barrierDismissible: false,
        title: const Text('Aucun compte disponible'),
        content: const Text(
          'Vous devez d\'abord créer un compte avant d\'ajouter un revenu.',
        ),
        actions: [
          FrostedTextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    RevenueBottomSheet.show(
      context: context,
      accounts: accountViewModel.accounts,
      onSubmit: (revenue) {
        revenueViewModel.addRevenue(revenue);
      },
      onCancel: () {},
    );
  }
}
