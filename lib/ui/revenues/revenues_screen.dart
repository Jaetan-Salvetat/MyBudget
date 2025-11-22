import 'package:flutter/material.dart';
import 'package:mybudget/ui/revenues/widgets/revenues_list.dart';

class RevenuesScreen extends StatelessWidget {
  const RevenuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [SizedBox(height: 100), Expanded(child: RevenuesList())],
    );
  }
}
