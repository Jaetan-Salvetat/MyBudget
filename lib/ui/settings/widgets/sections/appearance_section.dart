import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/theme_mode_display.dart';
import 'package:mybudget/core/theme/theme_provider.dart';
import 'package:mybudget/ui/settings/screens/theme_screen.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return FrostedListSection(
      label: 'Apparence',
      tiles: [
        FrostedListTile(
          title: 'Thème',
          subtitle: themeState.themeMode.label,
          leading: const FrostedListAvatar(icon: Symbols.brightness_6_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const ThemeScreen()),
          ),
        ),
      ],
    );
  }
}
