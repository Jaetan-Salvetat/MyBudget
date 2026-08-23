import 'package:mybudget/core/enums/frequency.dart';

/// The surface a transaction has to expose to be filtered, whatever side of
/// the budget it sits on.
abstract interface class FilterableTransaction {
  String get name;
  double get amount;
  int get accountId;
  int? get beneficiaryId;
  String? get categorySlug;
  Frequency get frequencyEnum;
}
