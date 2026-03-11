import 'package:flutter/material.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/screens/form_webview_screen.dart';

const _allowedHost = 'forms.jaetan.dev';
const _bugReportUrl = 'https://forms.jaetan.dev/p/bug-repport';
const _feedbackUrl = 'https://forms.jaetan.dev/p/feedback-ideas';

class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Support',
      children: [
        SettingsTile(
          title: 'Signaler un bug',
          subtitle: 'Aidez-nous à corriger les problèmes',
          leading: const Icon(Icons.bug_report_outlined),
          onTap: () => _openForm(context, 'Signaler un bug', _bugReportUrl),
        ),
        SettingsTile(
          title: 'Suggérer une amélioration',
          subtitle: 'Partagez vos idées et retours',
          leading: const Icon(Icons.lightbulb_outline),
          onTap: () => _openForm(context, 'Suggérer une amélioration', _feedbackUrl),
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
