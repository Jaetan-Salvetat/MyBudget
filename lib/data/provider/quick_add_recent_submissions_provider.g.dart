// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_recent_submissions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuickAddRecentSubmissions)
final quickAddRecentSubmissionsProvider = QuickAddRecentSubmissionsProvider._();

final class QuickAddRecentSubmissionsProvider
    extends
        $NotifierProvider<QuickAddRecentSubmissions, List<QuickAddSubmission>> {
  QuickAddRecentSubmissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quickAddRecentSubmissionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quickAddRecentSubmissionsHash();

  @$internal
  @override
  QuickAddRecentSubmissions create() => QuickAddRecentSubmissions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<QuickAddSubmission> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<QuickAddSubmission>>(value),
    );
  }
}

String _$quickAddRecentSubmissionsHash() =>
    r'e25d64961a0e78e6957252b27aec9b352f673510';

abstract class _$QuickAddRecentSubmissions
    extends $Notifier<List<QuickAddSubmission>> {
  List<QuickAddSubmission> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<List<QuickAddSubmission>, List<QuickAddSubmission>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<QuickAddSubmission>, List<QuickAddSubmission>>,
              List<QuickAddSubmission>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
