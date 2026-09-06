import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/providers/providers.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String version = ref.watch(appVersionProvider);
    final String build = ref.watch(appBuildNumberProvider);

    return FrostedListSection(
      label: 'À propos',
      tiles: [
        FrostedListTile(
          title: 'Version',
          subtitle: '$version ($build)',
          leading: const FrostedListAvatar(icon: Symbols.info_rounded),
        ),
      ],
    );
  }
}
