import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_account_provider.g.dart';

/// The account a quick-added transaction lands on. Defaults to the first one
/// and holds the user's pick as long as that account still exists.
@riverpod
class QuickAddAccountNotifier extends _$QuickAddAccountNotifier {
  int? _picked;

  @override
  int? build() {
    final accounts = ref.watch(accountProvider).value ?? [];
    if (accounts.isEmpty) return null;

    final picked = _picked;
    if (picked != null && accounts.any((account) => account.id == picked)) {
      return picked;
    }
    return accounts.first.id;
  }

  void select(int accountId) {
    _picked = accountId;
    state = accountId;
  }
}
