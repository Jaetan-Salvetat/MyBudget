import 'package:material_ui/material_ui.dart';
import 'package:mybudget/ui/loans/widgets/loans_list.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [Expanded(child: LoansList())]);
  }
}
