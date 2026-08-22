import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/ui/settings/screens/form_webview_screen.dart';
import 'package:mybudget/ui/settings/screens/help_screen.dart';

const _allowedHost = 'forms.jaetan.dev';
const _bugReportUrl = 'https://forms.jaetan.dev/p/bug-repport';
const _feedbackUrl = 'https://forms.jaetan.dev/p/feedback-ideas';

class HelpAndSupportSection extends StatelessWidget {
  const HelpAndSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FrostedListSection(
      label: 'Aide & Support',
      tiles: [
        FrostedListTile(
          title: 'Guide d\'utilisation',
          subtitle: 'Consultez l\'aide et les explications',
          leading: const FrostedListAvatar(icon: Symbols.help_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpScreen()),
          ),
        ),
        FrostedListTile(
          title: 'Signaler un bug',
          subtitle: 'Aidez-nous à corriger les problèmes',
          leading: const FrostedListAvatar(icon: Symbols.bug_report_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => _openForm(context, 'Signaler un bug', _bugReportUrl),
        ),
        FrostedListTile(
          title: 'Suggérer une amélioration',
          subtitle: 'Partagez vos idées et retours',
          leading: const FrostedListAvatar(icon: Symbols.lightbulb_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () =>
              _openForm(context, 'Suggérer une amélioration', _feedbackUrl),
        ),
      ],
    );
  }

  void _openForm(BuildContext context, String title, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormWebviewScreen(
          title: title,
          url: url,
          allowedHost: _allowedHost,
        ),
      ),
    );
  }
}
