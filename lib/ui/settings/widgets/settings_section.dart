import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        FrostedCard(
          margin: const EdgeInsets.only(bottom: 24),
          borderRadius: 16,
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}
