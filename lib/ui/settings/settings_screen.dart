import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'package:mybudget/ui/settings/widgets/sections/about_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/ai_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/appearance_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/data_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/debug_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/help_and_support_section.dart';
import 'package:mybudget/ui/settings/widgets/sections/input_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<Widget> _sections = [
    AppearanceSection(),
    InputSection(),
    AiSection(),
    DataSection(),
    HelpAndSupportSection(),
    AboutSection(),
    if (kDebugMode) DebugSection(),
  ];

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Paramètres',
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          FrostedSpacing.sp4,
          FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
          FrostedSpacing.sp4,
          FrostedSpacing.sp6,
        ),
        itemCount: _sections.length,
        itemBuilder: (_, int index) => _sections[index],
        separatorBuilder: (_, _) => const SizedBox(height: FrostedSpacing.sp6),
      ),
    );
  }
}
