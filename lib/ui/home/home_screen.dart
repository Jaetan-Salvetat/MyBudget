import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/accounts/accounts_screen.dart';
import 'package:mybudget/ui/common/widgets/frosted_background.dart';
import 'package:mybudget/ui/dashboard/dashboard_screen.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/quick_add/widgets/quick_add_section.dart';
import 'package:mybudget/ui/scan/scan_screen.dart';
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
    _NavItem('Accueil', Icons.dashboard_outlined, Icons.dashboard),
    _NavItem('Transactions', Icons.swap_vert_outlined, Icons.swap_vert),
    _NavItem(
      'Comptes',
      Icons.account_balance_outlined,
      Icons.account_balance,
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
              onScanRequested: () => _showImageSourceChoice(context),
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

  void _showImageSourceChoice(BuildContext context) {
    final accounts = ref.read(accountProvider).value ?? [];

    if (accounts.isEmpty) {
      _showNoAccountDialog(context, 'une dépense');
      return;
    }

    FrostedBottomSheet.show(
      context: context,
      title: 'Scanner un ticket',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FrostedListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Prendre une photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImageAndScan(context, ImageSource.camera);
            },
          ),
          FrostedListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choisir depuis la galerie'),
            onTap: () {
              Navigator.pop(context);
              _pickImageAndScan(context, ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageAndScan(
    BuildContext context,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanScreen(imageBytes: bytes),
        ),
      );
    }
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
