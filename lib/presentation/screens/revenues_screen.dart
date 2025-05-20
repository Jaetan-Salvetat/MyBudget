import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mybudget/presentation/widgets/revenues/revenues_list.dart';
import '../widgets/common/app_scaffold.dart';
import '../../core/controllers/revenue_controller.dart';
import '../../core/controllers/account_controller.dart';
import '../widgets/revenues/revenue_bottom_sheet.dart';

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
    const content = Column(children: [SizedBox(height: 100), RevenuesList()]);

    if (isNested) {
      return Stack(
        children: [
          content,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: fabTag,
              onPressed: () => _showAddRevenueBottomSheet(context),
              tooltip: 'Ajouter un revenu',
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return AppScaffold(
      title: 'Revenus',
      useNestedAppBar: false,
      floatingActionButton: FloatingActionButton(
        heroTag: fabTag,
        onPressed: () => _showAddRevenueBottomSheet(context),
        tooltip: 'Ajouter un revenu',
        child: const Icon(Icons.add),
      ),
      child: content,
    );
  }

  void _showAddRevenueBottomSheet(BuildContext context) {
    final accountController = Get.find<AccountController>();
    final revenueController = Get.find<RevenueController>();

    RevenueBottomSheet.show(
      context: context,
      accounts: accountController.accounts,
      onSubmit: (revenue) {
        revenueController.addRevenue(revenue);
        Navigator.of(context).pop();
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }
}
