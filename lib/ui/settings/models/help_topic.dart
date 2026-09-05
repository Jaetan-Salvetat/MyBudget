import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/build_flavor.dart';

enum HelpDestination {
  categories,
  beneficiaries,
  quickAddEngine,
  theme,
  update;

  bool isAvailableIn(BuildFlavor flavor) => switch (this) {
    HelpDestination.categories ||
    HelpDestination.beneficiaries ||
    HelpDestination.theme => true,
    HelpDestination.quickAddEngine => flavor.exposesQuickAddEngineSettings,
    HelpDestination.update => flavor.supportsInAppUpdate,
  };
}

class HelpAction {
  final String label;
  final HelpDestination destination;

  const HelpAction({required this.label, required this.destination});
}

class HelpTopic {
  static const int summaryMaxLength = 48;

  final String title;
  final String summary;
  final IconData icon;
  final List<String> paragraphs;
  final HelpAction? action;

  const HelpTopic({
    required this.title,
    required this.summary,
    required this.icon,
    required this.paragraphs,
    this.action,
  });
}

class HelpChapter {
  final String label;
  final List<HelpTopic> topics;

  const HelpChapter({required this.label, required this.topics});
}
