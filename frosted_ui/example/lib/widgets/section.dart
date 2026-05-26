import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

class Section extends StatelessWidget {
  const Section({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: FrostedTypeScale.labelSmall.copyWith(color: cs.primary),
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        child,
      ],
    );
  }
}
