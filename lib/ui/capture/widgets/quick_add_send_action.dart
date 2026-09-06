import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

enum QuickAddSendState { idle, ready, sending, sent }

class QuickAddSendAction extends StatelessWidget {
  const QuickAddSendAction({
    required this.state,
    required this.onSend,
    super.key,
  });
  static const double slot = 24;

  static const double gap = FrostedSpacing.sp2;

  static const double entryScale = 0.6;

  static const double entryRise = 6;

  final QuickAddSendState state;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final motion = context.frostedTokens.motion.snappy;

    return AnimatedSize(
      duration: motion.duration,
      curve: motion.curve,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: state == QuickAddSendState.idle ? 0 : gap + slot,
        height: slot,
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox.square(
            dimension: slot,
            child: AnimatedSwitcher(
              duration: motion.duration,
              switchInCurve: motion.curve,
              switchOutCurve: motion.curve,
              transitionBuilder: _rise,
              child: _content(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rise(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: entryScale, end: 1).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, entryRise / slot),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    switch (state) {
      case QuickAddSendState.idle:
        return const SizedBox.shrink(key: ValueKey(QuickAddSendState.idle));

      case QuickAddSendState.sending:
        return _Spinner(key: const ValueKey(QuickAddSendState.sending));

      case QuickAddSendState.ready:
        return _Glyph(
          key: const ValueKey(QuickAddSendState.ready),
          icon: Symbols.arrow_upward_rounded,
          color: color,
          tooltip: 'Envoyer',
          onTap: onSend,
        );

      case QuickAddSendState.sent:
        return _Glyph(
          key: const ValueKey(QuickAddSendState.sent),
          icon: Symbols.check_rounded,
          color: color,
          tooltip: 'Enregistré',
          onTap: null,
        );
    }
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    super.key,
  });
  static const double _size = 20;

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Icon(icon, size: _size, color: color),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({super.key});
  static const double _size = 16;
  static const double _stroke = 2;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: _size,
        child: CircularProgressIndicator(
          strokeWidth: _stroke,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
