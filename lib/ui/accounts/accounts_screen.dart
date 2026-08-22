import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/constants/layout_insets.dart';
import 'package:mybudget/ui/accounts/widgets/account_list.dart';
import 'package:mybudget/ui/common/widgets/month_selector.dart';
import 'package:mybudget/ui/settings/settings_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 0, 16, mainFlowBottomInset(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mes comptes',
                        style: TextStyle(
                          fontSize: 28,
                          height: 34 / 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.022 * 28,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    FrostedIconButton.tonal(
                      icon: Symbols.settings_rounded,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const MonthSelector(),
            const SizedBox(height: 4),
            const AccountList(),
          ],
        ),
      ),
    );
  }
}
