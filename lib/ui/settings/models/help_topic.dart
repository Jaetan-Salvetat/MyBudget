import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/build_flavor.dart';

enum HelpDestination {
  categories,
  beneficiaries,
  quickAddEngine,
  theme;

  bool isAvailableIn(BuildFlavor flavor) => switch (this) {
    HelpDestination.categories ||
    HelpDestination.beneficiaries ||
    HelpDestination.theme => true,
    HelpDestination.quickAddEngine => flavor.exposesQuickAddEngineSettings,
  };
}

class HelpAction {
  const HelpAction({required this.label, required this.destination});
  final String label;
  final HelpDestination destination;
}

class HelpTopic {
  const HelpTopic({
    required this.title,
    required this.summary,
    required this.icon,
    required this.paragraphs,
    this.action,
  });
  static const int summaryMaxLength = 48;

  final String title;
  final String summary;
  final IconData icon;
  final List<String> paragraphs;
  final HelpAction? action;
}

class HelpChapter {
  const HelpChapter({required this.label, required this.topics});
  final String label;
  final List<HelpTopic> topics;
}
