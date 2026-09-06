import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_account_provider.dart';

class QuickAddAccountLine extends ConsumerWidget {
  const QuickAddAccountLine({required this.onNoAccount, super.key});
  final VoidCallback onNoAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountProvider);
    final selectedId = ref.watch(quickAddAccountProvider);

    if (accounts.isEmpty) {
      return _Line(
        label: 'aucun compte — en créer un',
        onTap: onNoAccount,
        showChevron: false,
      );
    }

    final account = accounts.firstWhere(
      (candidate) => candidate.id == selectedId,
      orElse: () => accounts.first,
    );

    return _Line(
      label: 'enregistré sur ${account.name}',
      onTap: accounts.length > 1
          ? () => _pickAccount(context, ref, accounts)
          : null,
      showChevron: accounts.length > 1,
    );
  }

  Future<void> _pickAccount(
    BuildContext context,
    WidgetRef ref,
    List<AccountModel> accounts,
  ) async {
    final selectedId = ref.read(quickAddAccountProvider);
    final notifier = ref.read(quickAddAccountProvider.notifier);
    final picked = await showFrostedBottomSheet<int>(
      context: context,
      builder: (sheetContext) => FrostedBottomSheet(
        title: 'Compte',
        child: SingleChildScrollView(
          child: FrostedListSection(
            tiles: [
              for (final account in accounts)
                FrostedListTile(
                  title: account.name,
                  subtitle: account.bank,
                  selected: account.id == selectedId,
                  onTap: () => Navigator.pop(sheetContext, account.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    notifier.select(picked);
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.onTap,
    required this.showChevron,
  });
  final String label;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = AppTextStyles.mono(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FrostedRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.sp1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: style),
            if (showChevron) ...[
              const SizedBox(width: FrostedSpacing.sp1),
              Icon(
                Symbols.expand_more_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
