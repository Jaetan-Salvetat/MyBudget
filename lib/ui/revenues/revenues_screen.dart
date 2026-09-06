import 'package:material_ui/material_ui.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_list.dart';

class RevenuesScreen extends StatelessWidget {
  const RevenuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [Expanded(child: RevenuesList())]);
  }
}
