// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the month has left once everything it already owes is counted. The
/// capture screen shows that figure and nothing else : it is the consequence
/// of what was just typed, not a summary of the month.

@ProviderFor(remainingThisMonth)
final remainingThisMonthProvider = RemainingThisMonthProvider._();

/// What the month has left once everything it already owes is counted. The
/// capture screen shows that figure and nothing else : it is the consequence
/// of what was just typed, not a summary of the month.

final class RemainingThisMonthProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// What the month has left once everything it already owes is counted. The
  /// capture screen shows that figure and nothing else : it is the consequence
  /// of what was just typed, not a summary of the month.
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

/// The month so far, newest day first and newest line first inside each day.
/// The journal opens on what just happened and scrolls back through the
/// month ; days with nothing on them are left out rather than drawn empty.

@ProviderFor(monthJournal)
final monthJournalProvider = MonthJournalProvider._();

/// The month so far, newest day first and newest line first inside each day.
/// The journal opens on what just happened and scrolls back through the
/// month ; days with nothing on them are left out rather than drawn empty.

final class MonthJournalProvider
    extends
        $FunctionalProvider<
          List<JournalDay>,
          List<JournalDay>,
          List<JournalDay>
        >
    with $Provider<List<JournalDay>> {
  /// The month so far, newest day first and newest line first inside each day.
  /// The journal opens on what just happened and scrolls back through the
  /// month ; days with nothing on them are left out rather than drawn empty.
  MonthJournalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthJournalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthJournalHash();

  @$internal
  @override
  $ProviderElement<List<JournalDay>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<JournalDay> create(Ref ref) {
    return monthJournal(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<JournalDay> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<JournalDay>>(value),
    );
  }
}

String _$monthJournalHash() => r'38216b30d06e80eb3ecfd2f059751d4011084f36';

/// Today alone, for the figure above the list and for the hint that only
/// types itself out while the day is still bare.

@ProviderFor(todayJournal)
final todayJournalProvider = TodayJournalProvider._();

/// Today alone, for the figure above the list and for the hint that only
/// types itself out while the day is still bare.

final class TodayJournalProvider
    extends
        $FunctionalProvider<
          List<JournalEntry>,
          List<JournalEntry>,
          List<JournalEntry>
        >
    with $Provider<List<JournalEntry>> {
  /// Today alone, for the figure above the list and for the hint that only
  /// types itself out while the day is still bare.
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

String _$todayJournalHash() => r'aeea6d4b0dea97201d5591482cea4cb9479ee770';
