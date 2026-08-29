import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_shape.dart';
import '../../foundations/frosted_spacing.dart';
import '../../theme/frosted_motion_tokens.dart';
import '../../theme/frosted_tokens.dart';
import '_interactive_surface.dart';

enum _IconButtonVariant { standard, filled, tonal, outlined }

/// The three footprints an icon button can take.
///
/// [medium] is the default; [small] is for dense rows where the button trails
/// content, [large] for a lone target that has to carry a screen.
enum FrostedIconButtonSize {
  small(box: 32, glyph: 18),
  medium(box: 40, glyph: 22),
  large(box: 56, glyph: 24);

  const FrostedIconButtonSize({required this.box, required this.glyph});

  /// Side of the square touch target.
  final double box;

  /// Side of the icon inside it.
  final double glyph;
}

/// An icon-only button.
///
/// When [selected] is true and [selectedIcon] is provided, the filled
/// variant of the icon is shown.
///
/// [shape] picks the resting form — [FrostedShape.rounded] by default, or
/// [FrostedShape.pill], which on this square box is a circle. A press morphs
/// it into the other one and back.
class FrostedIconButton extends StatelessWidget {
  const FrostedIconButton._({
    super.key,
    required this.icon,
    required _IconButtonVariant variant,
    this.selectedIcon,
    this.selected = false,
    this.tooltip,
    this.onPressed,
    this.shape = FrostedShape.rounded,
    this.size = FrostedIconButtonSize.medium,
  }) : _variant = variant;

  factory FrostedIconButton.standard({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    bool selected = false,
    String? tooltip,
    required VoidCallback? onPressed,
    FrostedShape shape = FrostedShape.rounded,
    FrostedIconButtonSize size = FrostedIconButtonSize.medium,
  }) => FrostedIconButton._(
    key: key,
    icon: icon,
    variant: _IconButtonVariant.standard,
    selectedIcon: selectedIcon,
    selected: selected,
    tooltip: tooltip,
    onPressed: onPressed,
    shape: shape,
    size: size,
  );

  factory FrostedIconButton.filled({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    bool selected = false,
    String? tooltip,
    required VoidCallback? onPressed,
    FrostedShape shape = FrostedShape.rounded,
    FrostedIconButtonSize size = FrostedIconButtonSize.medium,
  }) => FrostedIconButton._(
    key: key,
    icon: icon,
    variant: _IconButtonVariant.filled,
    selectedIcon: selectedIcon,
    selected: selected,
    tooltip: tooltip,
    onPressed: onPressed,
    shape: shape,
    size: size,
  );

  factory FrostedIconButton.tonal({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    bool selected = false,
    String? tooltip,
    required VoidCallback? onPressed,
    FrostedShape shape = FrostedShape.rounded,
    FrostedIconButtonSize size = FrostedIconButtonSize.medium,
  }) => FrostedIconButton._(
    key: key,
    icon: icon,
    variant: _IconButtonVariant.tonal,
    selectedIcon: selectedIcon,
    selected: selected,
    tooltip: tooltip,
    onPressed: onPressed,
    shape: shape,
    size: size,
  );

  factory FrostedIconButton.outlined({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    bool selected = false,
    String? tooltip,
    required VoidCallback? onPressed,
    FrostedShape shape = FrostedShape.rounded,
    FrostedIconButtonSize size = FrostedIconButtonSize.medium,
  }) => FrostedIconButton._(
    key: key,
    icon: icon,
    variant: _IconButtonVariant.outlined,
    selectedIcon: selectedIcon,
    selected: selected,
    tooltip: tooltip,
    onPressed: onPressed,
    shape: shape,
    size: size,
  );

  final IconData icon;
  final IconData? selectedIcon;
  final bool selected;
  final String? tooltip;
  final VoidCallback? onPressed;

  /// The resting form. A press morphs it into [FrostedShape.opposite].
  final FrostedShape shape;

  /// The footprint of the touch target and the glyph it holds.
  final FrostedIconButtonSize size;

  final _IconButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final FrostedMotion motion = context.frostedTokens.motion.snappy;
    final IconData glyph = selected && selectedIcon != null
        ? selectedIcon!
        : icon;

    final Widget surface = InteractiveSurface(
      onTap: onPressed,
      cursor: SystemMouseCursors.click,
      semanticsLabel: tooltip,
      semanticsSelected: selected,
      builder: (BuildContext context, InteractionStates s) {
        final Color bg = _resolveBg(cs, s);
        final Color fg = _resolveFg(cs, s);
        final BorderSide? border = _resolveBorder(cs, s);

        return AnimatedContainer(
          duration: motion.duration,
          curve: motion.curve,
          width: size.box,
          height: size.box,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: _shape(s),
            border: border != null ? Border.fromBorderSide(border) : null,
          ),
          child: s.ink(
            Center(
              child: Icon(glyph, size: size.glyph, color: fg),
            ),
          ),
        );
      },
    );

    Widget result = Padding(
      padding: const EdgeInsets.all(FrostedSpacing.sp1),
      child: surface,
    );

    if (tooltip != null) {
      result = Tooltip(message: tooltip!, child: result);
    }
    return result;
  }

  BorderRadius _shape(InteractionStates s) =>
      shape.resolve(Size(size.box, size.box), pressed: s.pressed);

  Color _resolveBg(ColorScheme cs, InteractionStates s) {
    if (!s.enabled) {
      if (_variant == _IconButtonVariant.filled ||
          _variant == _IconButtonVariant.tonal) {
        return cs.onSurface.withValues(alpha: 0.12);
      }
      return Colors.transparent;
    }
    Color base;
    switch (_variant) {
      case _IconButtonVariant.standard:
        base = selected ? cs.primaryContainer : Colors.transparent;
        break;
      case _IconButtonVariant.filled:
        base = selected ? cs.primary : cs.surfaceContainerHighest;
        break;
      case _IconButtonVariant.tonal:
        base = selected ? cs.secondaryContainer : cs.surfaceContainerHigh;
        break;
      case _IconButtonVariant.outlined:
        base = selected ? cs.inverseSurface : Colors.transparent;
        break;
    }
    final Color overlay = _overlayBase(cs);
    final double alpha = _overlayAlpha(s);
    if (alpha == 0) return base;
    return Color.alphaBlend(overlay.withValues(alpha: alpha), base);
  }

  Color _resolveFg(ColorScheme cs, InteractionStates s) {
    if (!s.enabled) return cs.onSurface.withValues(alpha: 0.38);
    switch (_variant) {
      case _IconButtonVariant.standard:
        return selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
      case _IconButtonVariant.filled:
        return selected ? cs.onPrimary : cs.primary;
      case _IconButtonVariant.tonal:
        return selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;
      case _IconButtonVariant.outlined:
        return selected ? cs.onInverseSurface : cs.onSurfaceVariant;
    }
  }

  BorderSide? _resolveBorder(ColorScheme cs, InteractionStates s) {
    if (_variant != _IconButtonVariant.outlined) return null;
    if (selected) return null;
    if (!s.enabled) {
      return BorderSide(color: cs.onSurface.withValues(alpha: 0.12));
    }
    return BorderSide(color: cs.outline);
  }

  Color _overlayBase(ColorScheme cs) {
    switch (_variant) {
      case _IconButtonVariant.standard:
        return selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
      case _IconButtonVariant.filled:
        return selected ? cs.onPrimary : cs.primary;
      case _IconButtonVariant.tonal:
        return selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;
      case _IconButtonVariant.outlined:
        return selected ? cs.onInverseSurface : cs.onSurfaceVariant;
    }
  }

  double _overlayAlpha(InteractionStates s) {
    if (s.pressed) return 0.12;
    if (s.focused) return 0.10;
    if (s.hovered) return 0.08;
    return 0;
  }
}
