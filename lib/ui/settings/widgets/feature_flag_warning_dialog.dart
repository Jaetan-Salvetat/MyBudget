import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/feature_flag.dart';
import 'package:mybudget/ui/settings/widgets/settings_note.dart';

class FeatureFlagWarningDialog extends StatelessWidget {
  const FeatureFlagWarningDialog({required this.flag, super.key});

  static const String reversibleNote =
      'Tu peux la désactiver à tout moment depuis le Labo.';

  static const String suspensionNote =
      'Elle peut être suspendue à distance si un défaut est découvert.';

  static const double maxBodyHeightRatio = 0.6;

  final FeatureFlag flag;

  static Future<bool> show(BuildContext context, FeatureFlag flag) async {
    final bool? accepted = await showFrostedDialog<bool>(
      context: context,
      builder: (_) => FeatureFlagWarningDialog(flag: flag),
    );
    return accepted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FrostedDialog(
      title: 'Activer ${flag.label} ?',
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxBodyHeightRatio,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsNote.prominent(
                icon: Symbols.warning_rounded,
                text: flag.risk,
              ),
              const SizedBox(height: FrostedSpacing.sp3),
              const SettingsNote.prominent(
                icon: Symbols.cloud_off_rounded,
                text: suspensionNote,
              ),
              const SizedBox(height: FrostedSpacing.sp3),
              const SettingsNote.prominent(
                icon: Symbols.undo_rounded,
                text: reversibleNote,
              ),
            ],
          ),
        ),
      ),
      actions: [
        FrostedButton.text(
          label: 'Annuler',
          onPressed: () => Navigator.pop(context, false),
        ),
        FrostedButton.text(
          label: 'Activer',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
