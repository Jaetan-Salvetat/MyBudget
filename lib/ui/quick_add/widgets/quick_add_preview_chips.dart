import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

/// The category the app believes the text belongs to, ready to be drawn.
class QuickAddCategoryPreview {
  final String label;
  final IconData icon;
  final Color color;

  /// The model is not confident enough to stand behind it : the chip says so
  /// rather than passing it off as read.
  final bool isUncertain;

  const QuickAddCategoryPreview({
    required this.label,
    required this.icon,
    required this.color,
    required this.isUncertain,
  });
}

/// What the app understood of the text being typed, one chip per piece,
/// appearing as they land.
class QuickAddPreviewChips extends StatelessWidget {
  static const Duration chipStagger = Duration(milliseconds: 80);

  final String? amountLabel;
  final QuickAddCategoryPreview? category;
  final String? recurrenceLabel;
  final bool isAnalyzing;
  final VoidCallback onPickCategory;

  const QuickAddPreviewChips({
    required this.amountLabel,
    required this.category,
    required this.recurrenceLabel,
    required this.isAnalyzing,
    required this.onPickCategory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (amountLabel != null)
        FrostedChip.readOnly(label: amountLabel!, icon: Symbols.euro_rounded),
      if (category != null) _categoryChip(category!),
      if (recurrenceLabel != null)
        FrostedChip.readOnly(
          label: recurrenceLabel!,
          icon: Symbols.repeat_rounded,
        ),
      if (isAnalyzing && category == null)
        FrostedChip.readOnly(
          label: 'analyse…',
          icon: Symbols.auto_awesome_rounded,
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: FrostedSpacing.sp2,
      runSpacing: FrostedSpacing.sp2,
      children: [
        for (var i = 0; i < chips.length; i++)
          _FadeUpIn(delay: chipStagger * i, child: chips[i]),
      ],
    );
  }

  Widget _categoryChip(QuickAddCategoryPreview category) {
    if (category.isUncertain) {
      return FrostedChip.suggestion(
        label: category.label,
        onTap: onPickCategory,
      );
    }
    return FrostedChip.assist(
      label: category.label,
      icon: category.icon,
      onTap: onPickCategory,
    );
  }
}

/// Fades a chip in from below, [delay] after it enters the tree.
class _FadeUpIn extends StatefulWidget {
  final Duration delay;
  final Widget child;

  const _FadeUpIn({required this.delay, required this.child});

  @override
  State<_FadeUpIn> createState() => _FadeUpInState();
}

class _FadeUpInState extends State<_FadeUpIn>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 240);
  static const Offset _from = Offset(0, 0.35);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );
  Timer? _start;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _start = Timer(widget.delay, _controller.forward);
    }
  }

  @override
  void dispose() {
    _start?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: context.frostedTokens.motion.snappy.curve,
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: _from,
          end: Offset.zero,
        ).animate(animation),
        child: widget.child,
      ),
    );
  }
}
