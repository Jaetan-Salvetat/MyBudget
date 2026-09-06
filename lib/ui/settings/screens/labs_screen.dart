import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/feature_flag.dart';
import 'package:mybudget/data/provider/feature_flags_provider.dart';
import 'package:mybudget/ui/settings/widgets/feature_flag_warning_dialog.dart';
import 'package:mybudget/ui/settings/widgets/settings_note.dart';

class LabsScreen extends ConsumerWidget {
  const LabsScreen({super.key});

  static const String title = 'Labo';

  static const String bannerMessage =
      'Ces fonctionnalités sont encore en cours de mise au point. Elles '
      'peuvent se tromper, changer d\'aspect ou disparaître d\'une version '
      'à l\'autre. Vérifie toujours ce qu\'elles écrivent.';

  static const String blockedNote =
      'Suspendue à distance le temps qu\'un correctif soit publié.';

  static const String resetLabel = 'Tout remettre par défaut';

  static const String emptyNote =
      'Aucune fonctionnalité expérimentale en ce moment. Il y en aura ici '
      'quand une nouveauté sera prête à être essayée.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<FeatureFlag> flags = ref.watch(featureFlagRegistryProvider);

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: title,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          FrostedSpacing.sp4,
          FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
          FrostedSpacing.sp4,
          FrostedSpacing.sp6,
        ),
        children: [
          const FrostedBanner(
            message: bannerMessage,
            icon: Symbols.warning_rounded,
            tone: FrostedBannerTone.warning,
          ),
          const SizedBox(height: FrostedSpacing.sp6),
          if (flags.isEmpty)
            const SettingsNote(icon: Symbols.science_rounded, text: emptyNote)
          else ...[
            for (final FeatureFlag flag in flags) ...[
              _FlagCard(flag: flag),
              const SizedBox(height: FrostedSpacing.sp6),
            ],
            const _ResetAction(),
          ],
        ],
      ),
    );
  }
}

class _FlagCard extends ConsumerWidget {
  const _FlagCard({required this.flag});

  final FeatureFlag flag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(featureEnabledProvider(flag));
    final bool blocked = ref.watch(featureBlockedProvider(flag));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FrostedListSection(
          label: flag.stage.label,
          tiles: [
            FrostedListTile(
              title: flag.label,
              subtitle: flag.description,
              leading: const FrostedListAvatar(icon: Symbols.science_rounded),
              trailing: FrostedSwitch(
                value: enabled,
                onChanged: blocked
                    ? null
                    : (bool value) => _toggle(context, ref, value),
              ),
              onTap: blocked ? null : () => _toggle(context, ref, !enabled),
            ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        SettingsNote(
          icon: blocked ? Symbols.block_rounded : Symbols.warning_rounded,
          text: blocked ? LabsScreen.blockedNote : flag.risk,
        ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    if (value && !await FeatureFlagWarningDialog.show(context, flag)) return;

    await ref.read(featureFlagChoicesProvider.notifier).choose(flag.id, value);
  }
}

class _ResetAction extends ConsumerWidget {
  const _ResetAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FrostedButton.text(
      label: LabsScreen.resetLabel,
      icon: Symbols.restart_alt_rounded,
      expanded: true,
      onPressed: () => ref.read(featureFlagChoicesProvider.notifier).resetAll(),
    );
  }
}
