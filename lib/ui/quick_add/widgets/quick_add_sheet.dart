import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'package:mybudget/ui/quick_add/widgets/quick_add_section.dart';

class QuickAddSheet extends StatelessWidget {
  final VoidCallback onNoAccount;

  const QuickAddSheet({required this.onNoAccount, super.key});

  @override
  Widget build(BuildContext context) {
    return FrostedBottomSheet(
      title: 'Ajout rapide',
      child: QuickAddSection(onNoAccount: onNoAccount),
    );
  }
}
