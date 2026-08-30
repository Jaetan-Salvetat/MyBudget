import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Ce que la poignée du champ a à offrir à l'instant : rien tant que le texte
/// n'est pas une transaction, puis l'envoi, l'attente, et l'accusé.
enum QuickAddSendState {
  /// Il n'y a pas de quoi envoyer. La poignée n'est pas grisée, elle n'est pas
  /// là : un bouton mort dit moins bien « pas encore » que son absence.
  idle,

  /// La transaction tient debout, le geste est à un pouce.
  ready,

  /// L'écriture est partie.
  sending,

  /// Elle est posée. Le champ est déjà vide pour la suivante.
  sent,
}

/// L'envoi, à l'intérieur du champ, là où un mot de passe met son œil.
///
/// Tant qu'il n'y a rien à envoyer il ne garde pas sa place : la sortie tient
/// alors le bord du champ, et c'est en glissant qu'elle lui cède la sienne.
class QuickAddSendAction extends StatelessWidget {
  /// Côté du carré que la poignée occupe dans le champ. Il tient dans la
  /// hauteur d'une ligne : le champ ne grandit pas quand l'envoi apparaît.
  static const double slot = 24;

  /// L'air qui sépare l'envoi de la sortie, replié avec lui quand il n'est
  /// pas là.
  static const double gap = FrostedSpacing.sp2;

  /// D'où le glyphe arrive. Assez petit pour qu'on voie qu'il se pose, assez
  /// grand pour rester lisible pendant tout le trajet.
  static const double entryScale = 0.6;

  /// La distance dont il monte en arrivant, dans le sens du geste qu'il
  /// propose.
  static const double entryRise = 6;

  final QuickAddSendState state;
  final VoidCallback onSend;

  const QuickAddSendAction({
    required this.state,
    required this.onSend,
    super.key,
  });

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

  /// Le glyphe monte en se posant plutôt qu'en apparaissant : c'est le geste
  /// qu'il propose, joué en petit.
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
  static const double _size = 20;

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _Glyph({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(child: Icon(icon, size: _size, color: color)),
      ),
    );
  }
}

/// L'attente, dans l'empreinte du glyphe qu'elle remplace.
class _Spinner extends StatelessWidget {
  static const double _size = 16;
  static const double _stroke = 2;

  const _Spinner({super.key});

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
