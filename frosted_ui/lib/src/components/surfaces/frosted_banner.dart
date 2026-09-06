import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_radius.dart';
import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import '../actions/frosted_button.dart';

enum FrostedBannerTone { info, warning }

class FrostedBanner extends StatelessWidget {
  const FrostedBanner({
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.tone = FrostedBannerTone.info,
    super.key,
  });

  static const Color warningSurfaceLight = Color(0xFFFFE0A3);
  static const Color warningContentLight = Color(0xFF4A2B00);
  static const Color warningSurfaceDark = Color(0xFF4A3200);
  static const Color warningContentDark = Color(0xFFFFDCA8);

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final FrostedBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;
    final Color surface = switch (tone) {
      FrostedBannerTone.info => cs.secondaryContainer,
      FrostedBannerTone.warning =>
        dark ? warningSurfaceDark : warningSurfaceLight,
    };
    final Color content = switch (tone) {
      FrostedBannerTone.info => cs.onSecondaryContainer,
      FrostedBannerTone.warning =>
        dark ? warningContentDark : warningContentLight,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FrostedSpacing.sp4,
        vertical: FrostedSpacing.sp3 + 2,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(FrostedRadius.lg),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 22, color: content),
            const SizedBox(width: FrostedSpacing.sp3 + 2),
          ],
          Expanded(
            child: Text(
              message,
              style: FrostedTypeScale.bodyMedium.copyWith(color: content),
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(width: FrostedSpacing.sp2),
            FrostedButton.text(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
