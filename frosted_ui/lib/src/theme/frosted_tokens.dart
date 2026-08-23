import 'package:material_ui/material_ui.dart';

import 'frosted_glass_tokens.dart';
import 'frosted_motion_tokens.dart';
import 'frosted_state_tokens.dart';

/// Aggregated theme extension carrying every Frosted UI token that is not
/// already expressed by Flutter's `ColorScheme`, `TextTheme`, or constant
/// foundations (spacing, radius).
///
/// Resolve via `Theme.of(context).extension<FrostedTokens>()!` or the
/// [BuildContextFrostedTokens.frostedTokens] helper.
class FrostedTokens extends ThemeExtension<FrostedTokens> {
  const FrostedTokens({
    required this.glass,
    required this.motion,
    required this.state,
  });

  final FrostedGlassTokens glass;
  final FrostedMotionTokens motion;
  final FrostedStateTokens state;

  @override
  FrostedTokens copyWith({
    FrostedGlassTokens? glass,
    FrostedMotionTokens? motion,
    FrostedStateTokens? state,
  }) {
    return FrostedTokens(
      glass: glass ?? this.glass,
      motion: motion ?? this.motion,
      state: state ?? this.state,
    );
  }

  @override
  FrostedTokens lerp(ThemeExtension<FrostedTokens>? other, double t) {
    if (other is! FrostedTokens) {
      return this;
    }
    return FrostedTokens(
      glass: FrostedGlassTokens.lerp(glass, other.glass, t),
      motion: FrostedMotionTokens.lerp(motion, other.motion, t),
      state: FrostedStateTokens.lerp(state, other.state, t),
    );
  }
}

extension BuildContextFrostedTokens on BuildContext {
  /// Resolve the [FrostedTokens] attached to the ambient theme.
  ///
  /// Throws if no [FrostedTokens] extension was registered — call
  /// `FrostedTheme.light(...)` or `.dark(...)` when building your [ThemeData].
  FrostedTokens get frostedTokens {
    final FrostedTokens? tokens = Theme.of(this).extension<FrostedTokens>();
    assert(
      tokens != null,
      'FrostedTokens extension missing. Use FrostedTheme.light/.dark to build your ThemeData.',
    );
    return tokens!;
  }
}
