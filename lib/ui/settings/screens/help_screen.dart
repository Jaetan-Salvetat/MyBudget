import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/build_flavor.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/ui/settings/help_content.dart';
import 'package:mybudget/ui/settings/models/help_topic.dart';
import 'package:mybudget/ui/settings/screens/beneficiaries_screen.dart';
import 'package:mybudget/ui/settings/screens/categories_screen.dart';
import 'package:mybudget/ui/settings/screens/quick_add_engine_screen.dart';
import 'package:mybudget/ui/settings/screens/theme_screen.dart';

Widget helpDestinationScreen(HelpDestination destination) {
  switch (destination) {
    case HelpDestination.categories:
      return const CategoriesScreen();
    case HelpDestination.beneficiaries:
      return const BeneficiariesScreen();
    case HelpDestination.quickAddEngine:
      return const QuickAddEngineScreen();
    case HelpDestination.theme:
      return const ThemeScreen();
  }
}

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  String? _openTitle;

  void _toggle(HelpTopic topic, bool expanded) {
    setState(() => _openTitle = expanded ? topic.title : null);
  }

  void _open(HelpDestination destination) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => helpDestinationScreen(destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BuildFlavor flavor = ref.watch(buildFlavorProvider);

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Aide',
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
        itemCount: helpChapters.length,
        itemBuilder: (_, int index) => _Chapter(
          chapter: helpChapters[index],
          flavor: flavor,
          openTitle: _openTitle,
          onToggle: _toggle,
          onAction: _open,
        ),
        separatorBuilder: (_, _) => const SizedBox(height: FrostedSpacing.sp6),
      ),
    );
  }
}

class _Chapter extends StatelessWidget {
  const _Chapter({
    required this.chapter,
    required this.flavor,
    required this.openTitle,
    required this.onToggle,
    required this.onAction,
  });
  static const double _gap = FrostedSpacing.sp05;

  final HelpChapter chapter;
  final BuildFlavor flavor;
  final String? openTitle;
  final void Function(HelpTopic topic, bool expanded) onToggle;
  final ValueChanged<HelpDestination> onAction;

  HelpAction? _actionFor(HelpTopic topic) {
    final HelpAction? action = topic.action;
    if (action == null || !action.destination.isAvailableIn(flavor)) {
      return null;
    }
    return action;
  }

  FrostedTilePosition _positionFor(int index) {
    final bool isFirst = index == 0;
    final bool isLast = index == chapter.topics.length - 1;
    if (isFirst && isLast) return FrostedTilePosition.single;
    if (isFirst) return FrostedTilePosition.first;
    if (isLast) return FrostedTilePosition.last;
    return FrostedTilePosition.middle;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: FrostedSpacing.sp3),
          child: Text(
            chapter.label,
            style: FrostedTypeScale.titleSmall.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
        for (int i = 0; i < chapter.topics.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          _TopicTile(
            topic: chapter.topics[i],
            action: _actionFor(chapter.topics[i]),
            position: _positionFor(i),
            expanded: chapter.topics[i].title == openTitle,
            onToggle: onToggle,
            onAction: onAction,
          ),
        ],
      ],
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.action,
    required this.position,
    required this.expanded,
    required this.onToggle,
    required this.onAction,
  });
  final HelpTopic topic;
  final HelpAction? action;
  final FrostedTilePosition position;
  final bool expanded;
  final void Function(HelpTopic topic, bool expanded) onToggle;
  final ValueChanged<HelpDestination> onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final HelpAction? action = this.action;

    return FrostedExpansionTile(
      title: topic.title,
      subtitle: topic.summary,
      leading: Icon(topic.icon),
      position: position,
      expanded: expanded,
      onExpansionChanged: (bool open) => onToggle(topic, open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (int index, String paragraph)
              in topic.paragraphs.indexed) ...[
            if (index > 0) const SizedBox(height: FrostedSpacing.sp3),
            Text(
              paragraph,
              style: FrostedTypeScale.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: FrostedSpacing.sp2),
            Align(
              alignment: Alignment.centerLeft,
              child: FrostedButton.text(
                label: action.label,
                trailingIcon: Symbols.arrow_forward_rounded,
                onPressed: () => onAction(action.destination),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
