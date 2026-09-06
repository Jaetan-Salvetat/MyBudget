// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AccountNotifier)
final accountProvider = AccountNotifierProvider._();

final class AccountNotifierProvider
    extends $NotifierProvider<AccountNotifier, List<AccountModel>> {
  AccountNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountNotifierHash();

  @$internal
  @override
  AccountNotifier create() => AccountNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<AccountModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<AccountModel>>(value),
    );
  }
}

String _$accountNotifierHash() => r'ac21b5588ac2f8818e31b217872beaeeaceee912';

abstract class _$AccountNotifier extends $Notifier<List<AccountModel>> {
  List<AccountModel> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<AccountModel>, List<AccountModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<AccountModel>, List<AccountModel>>,
              List<AccountModel>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
