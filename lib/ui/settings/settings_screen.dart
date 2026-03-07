import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'package:mybudget/ui/settings/widgets/sections/appearance_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/financial_calculations_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/beneficiaries_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/categories_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/data_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/help_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/about_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/debug_section.dart';
import 'package:flutter/foundation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      appBar: FrostedAppBar(
        title: 'Paramètres',
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 130,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        children: const [
          AppearanceSection(),
          FinancialCalculationsSection(),
          CategoriesSection(),
          BeneficiariesSection(),
          DataSection(),
          HelpSection(),
          AboutSection(),
          if (kDebugMode) DebugSection(),
        ],
      ),
    );
  }
}
