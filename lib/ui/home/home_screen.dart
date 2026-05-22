import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/accounts/accounts_screen.dart';
import 'package:mybudget/ui/common/widgets/frosted_background.dart';
import 'package:mybudget/ui/dashboard/dashboard_screen.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_section.dart';
import 'package:mybudget/ui/settings/screens/update_screen.dart';
import 'package:mybudget/ui/settings/update_provider.dart';
import 'package:mybudget/ui/transactions/transactions_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeScreen({this.initialIndex = 0, super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _selectedIndex;
  int _transactionsSubTab = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateProvider.notifier).checkForUpdates(silent: true);
      ref.listenManual(updateProvider, (previous, next) {
        if (previous?.availableUpdate == null &&
            next.availableUpdate != null &&
            context.mounted) {
          FrostedSnackbar.show(
            context,
            message: 'Mise à jour v${next.availableUpdate!.version} disponible',
            action: SnackBarAction(
              label: 'Voir',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateScreen()),
              ),
            ),
          );
        }
      });
    });
  }

  static const List<_NavItem> _items = [
    _NavItem('Accueil', Symbols.dashboard_rounded, Symbols.dashboard_rounded),
    _NavItem('Transactions', Symbols.swap_vert_rounded, Symbols.swap_vert_rounded),
    _NavItem(
      'Comptes',
      Symbols.account_balance_rounded,
      Symbols.account_balance_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    final screens = [
      const DashboardScreen(isNested: true, fabTag: 'dashboard_fab_nested'),
      TransactionsScreen(
        selectedTab: _transactionsSubTab,
        onTabChanged: (i) => setState(() => _transactionsSubTab = i),
      ),
      const AccountsScreen(),
    ];

    return FrostedScaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuickAddSection(
              onNoAccount: () => _showNoAccountDialog(context, 'une dépense'),
            ),
            if (!keyboardVisible)
              FrostedBottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  if (_selectedIndex != index) {
                    setState(() => _selectedIndex = index);
                  }
                },
                items: _items
                    .map(
                      (item) => BottomNavigationBarItem(
                        icon: Icon(item.icon),
                        activeIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
      child: FrostedBackground(
        child: Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: screens),
            _QuickAddScrim(),
          ],
        ),
      ),
    );
  }

  void _showNoAccountDialog(BuildContext context, String action) {
    FrostedDialog.show(
      context: context,
      barrierDismissible: false,
      title: const Text('Aucun compte disponible'),
      content: Text(
        'Vous devez d\'abord créer un compte avant d\'ajouter $action.',
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem(this.label, this.icon, this.selectedIcon);
}

class _QuickAddScrim extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quickAddProvider);
    final hasResult = state.hasValue && state.value != null;
    final isVisible = hasResult || state.isLoading || state.hasError;
    final dismissible = hasResult || state.hasError;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        opacity: isVisible ? 1 : 0,
        child: GestureDetector(
          onTap: dismissible
              ? () => ref.read(quickAddProvider.notifier).reset()
              : null,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: FrostedBlur.medium,
              sigmaY: FrostedBlur.medium,
            ),
            child: ColoredBox(
              color: Colors.black.withValues(alpha: FrostedOpacity.half),
            ),
          ),
        ),
      ),
    );
  }
}
