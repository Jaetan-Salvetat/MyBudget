import 'package:mybudget/core/enums/frequency.dart';

abstract interface class FilterableTransaction {
  String get name;
  double get amount;
  int get accountId;
  int? get beneficiaryId;
  String? get categorySlug;
  DateTime get startDate;
  DateTime? get endDate;
  Frequency get frequencyEnum;
}
