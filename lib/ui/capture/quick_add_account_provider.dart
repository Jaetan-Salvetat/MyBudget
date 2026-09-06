import 'dart:async';

import 'package:mybudget/data/provider/accounts_provider.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_account_provider.g.dart';

@Riverpod(keepAlive: true)
class QuickAddAccountNotifier extends _$QuickAddAccountNotifier {
  int? _picked = PreferencesService.getQuickAddAccountId();

  @override
  int? build() {
    final accounts = ref.watch(accountProvider);
    if (accounts.isEmpty) return null;

    final picked = _picked;
    if (picked != null && accounts.any((account) => account.id == picked)) {
      return picked;
    }
    if (picked != null) _forget();

    return accounts.first.id;
  }

  void select(int accountId) {
    _picked = accountId;
    unawaited(PreferencesService.setQuickAddAccountId(accountId));
    state = accountId;
  }

  void _forget() {
    _picked = null;
    unawaited(PreferencesService.clearQuickAddAccountId());
  }
}
