import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/ui/common/widgets/frosted_container.dart';
import 'package:mybudget/ui/scan/widgets/scan_motion.dart';

class ScanCommitBar extends StatelessWidget {
  const ScanCommitBar({
    required this.pendingCount,
    required this.total,
    required this.accounts,
    required this.selectedAccountId,
    required this.onSelectAccount,
    required this.onFocusPending,
    required this.onCommit,
    super.key,
  });
  static const String noAccountLabel = 'Créez un compte pour enregistrer';

  static String pendingLabelOf(int count) =>
      count > 1 ? 'Ranger $count articles' : 'Ranger 1 article';

  static String commitLabelOf(double total) =>
      'Enregistrer ${MoneyFormatter.format(total)}';

  final int pendingCount;
  final double total;
  final List<AccountModel> accounts;
  final int? selectedAccountId;
  final ValueChanged<int> onSelectAccount;
  final VoidCallback onFocusPending;
  final VoidCallback onCommit;

  AccountModel? get _selected {
    if (accounts.isEmpty) return null;
    for (final account in accounts) {
      if (account.id == selectedAccountId) return account;
    }
    return accounts.first;
  }

  @override
  Widget build(BuildContext context) {
    return FrostedContainer(
      padding: const EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        FrostedSpacing.sp3,
        FrostedSpacing.sp4,
        FrostedSpacing.sp4,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (accounts.length > 1) ...[
              _AccountLine(
                label: _selected?.name ?? '',
                onTap: () => _pickAccount(context),
              ),
              const SizedBox(height: FrostedSpacing.sp2),
            ],
            ScanSwap(child: _action(context)),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context) {
    if (pendingCount > 0) {
      return SizedBox(
        key: ValueKey('pending-$pendingCount'),
        width: double.infinity,
        child: FrostedButton.outlined(
          label: pendingLabelOf(pendingCount),
          onPressed: onFocusPending,
        ),
      );
    }

    if (accounts.isEmpty) {
      return Padding(
        key: const ValueKey('no-account'),
        padding: const EdgeInsets.only(bottom: FrostedSpacing.sp2),
        child: Text(
          noAccountLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      key: const ValueKey('commit'),
      width: double.infinity,
      child: FrostedButton.filled(
        label: commitLabelOf(total),
        onPressed: onCommit,
      ),
    );
  }

  Future<void> _pickAccount(BuildContext context) async {
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
                  selected: account.id == _selected?.id,
                  onTap: () => Navigator.pop(sheetContext, account.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    onSelectAccount(picked);
  }
}

class _AccountLine extends StatelessWidget {
  const _AccountLine({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FrostedRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.sp1,
          vertical: FrostedSpacing.sp1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'enregistré sur $label',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: FrostedSpacing.sp1),
            Icon(
              Symbols.expand_more_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
