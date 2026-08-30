import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'package:mybudget/core/theme/theme_mode_display.dart';
import 'package:mybudget/core/theme/theme_provider.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode selected = ref.watch(themeProvider).themeMode;

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Thème',
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
          FrostedListSection(
            label: 'Apparence',
            tiles: [
              for (final mode in ThemeMode.values)
                FrostedListTile(
                  title: mode.label,
                  subtitle: mode.description,
                  leading: FrostedRadio<ThemeMode>(
                    value: mode,
                    groupValue: selected,
                    onChanged: (_) => _select(ref, mode),
                  ),
                  onTap: () => _select(ref, mode),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _select(WidgetRef ref, ThemeMode mode) {
    ref.read(themeProvider.notifier).setThemeMode(mode);
  }
}
