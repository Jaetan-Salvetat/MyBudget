import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/settings/screens/update_screen.dart';
import 'package:mybudget/ui/settings/update_provider.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String version = ref.watch(appVersionProvider);
    final bool updatable = ref.watch(buildFlavorProvider).supportsInAppUpdate;

    return FrostedListSection(
      label: 'À propos',
      tiles: [
        FrostedListTile(
          title: 'Version',
          subtitle: version,
          leading: const FrostedListAvatar(icon: Symbols.info_rounded),
          trailing: updatable ? _UpdateAffordance() : null,
          onTap: updatable ? () => _openUpdateScreen(context) : null,
        ),
      ],
    );
  }

  void _openUpdateScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpdateScreen()),
    );
  }
}

class _UpdateAffordance extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasUpdate =
        ref.watch(updateProvider).availableUpdate != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasUpdate) ...[
          const FrostedBadgeView(badge: FrostedBadge.dot()),
          const SizedBox(width: FrostedSpacing.sp2),
        ],
        const Icon(Symbols.chevron_right_rounded),
      ],
    );
  }
}
