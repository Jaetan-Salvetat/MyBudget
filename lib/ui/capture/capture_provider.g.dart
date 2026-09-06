// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(remainingThisMonth)
final remainingThisMonthProvider = RemainingThisMonthProvider._();

final class RemainingThisMonthProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  RemainingThisMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remainingThisMonthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remainingThisMonthHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return remainingThisMonth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$remainingThisMonthHash() =>
    r'9136ff2a5737a2ca0440aea27772a0441c7e3844';

@ProviderFor(journalBuckets)
final journalBucketsProvider = JournalBucketsProvider._();

final class JournalBucketsProvider
    extends
        $FunctionalProvider<
          List<JournalBucket>,
          List<JournalBucket>,
          List<JournalBucket>
        >
    with $Provider<List<JournalBucket>> {
  JournalBucketsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalBucketsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalBucketsHash();

  @$internal
  @override
  $ProviderElement<List<JournalBucket>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<JournalBucket> create(Ref ref) {
    return journalBuckets(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<JournalBucket> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<JournalBucket>>(value),
    );
  }
}

String _$journalBucketsHash() => r'6e0508f30bb03b672aee7f19e7ccfd56fb006c77';

@ProviderFor(todayJournal)
final todayJournalProvider = TodayJournalProvider._();

final class TodayJournalProvider
    extends
        $FunctionalProvider<
          List<JournalEntry>,
          List<JournalEntry>,
          List<JournalEntry>
        >
    with $Provider<List<JournalEntry>> {
  TodayJournalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayJournalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayJournalHash();

  @$internal
  @override
  $ProviderElement<List<JournalEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<JournalEntry> create(Ref ref) {
    return todayJournal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<JournalEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<JournalEntry>>(value),
    );
  }
}

String _$todayJournalHash() => r'8c7407867e6896be8dc50918d893ac3f568d6bc4';
