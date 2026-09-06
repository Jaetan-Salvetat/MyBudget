import 'package:mybudget/core/entities/recurring_transaction.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/utils/json_fields.dart';
import 'package:objectbox/objectbox.dart';

const _sentinel = Object();

@Entity()
class ExpenseModel implements RecurringTransaction<ExpenseModel> {
  ExpenseModel();

  ExpenseModel.create({
    required this.name,
    required this.amount,
    this.categorySlug,
    required this.startDate,
    required Frequency frequency,
    required this.accountId,
    this.endDate,
    this.parentId,
    this.beneficiaryId,
    this.receiptPath,
  }) {
    this.frequency = frequency.storageKey;
  }

  factory ExpenseModel.fromJson(
    Map<String, dynamic> json, {
    required DateTime now,
  }) {
    final model = ExpenseModel()
      ..id = json.readInt('id', 0)
      ..name = json.readString('name', '')
      ..amount = json.readDouble('amount', 0)
      ..startDate = json.readFirstDate(const ['startDate', 'date']) ?? now
      ..endDate = json.readOptionalDate('endDate')
      ..parentId = json.readOptionalInt('parentId')
      ..frequencyEnum = Frequency.fromStorage(
        json.readString('frequency', Frequency.monthly.storageKey),
      )
      ..categorySlug = json.readOptionalString('categorySlug')
      ..accountId = json.readInt('accountId', 0)
      ..beneficiaryId = json.readOptionalInt('beneficiaryId')
      ..receiptPath = json.readOptionalString('receiptPath');
    return model;
  }
  @override
  @Id()
  int id = 0;

  @Index()
  @override
  late String name;

  @override
  late double amount;

  @Index()
  @override
  String? categorySlug;

  @Property(uid: 6567315342602454646)
  int? legacyCategoryId;

  @override
  @Property(uid: 7133072174613285923)
  late DateTime startDate;

  @Property()
  @override
  DateTime? endDate;

  @override
  int? parentId;

  late String frequency;

  @override
  late int accountId;

  @override
  int? beneficiaryId;

  String? receiptPath;

  ExpenseModel copyWith({
    String? name,
    double? amount,
    String? categorySlug,
    DateTime? startDate,
    Frequency? frequency,
    int? accountId,
    Object? endDate = _sentinel,
    Object? parentId = _sentinel,
    Object? beneficiaryId = _sentinel,
    Object? receiptPath = _sentinel,
  }) {
    final model = ExpenseModel()
      ..id = id
      ..name = name ?? this.name
      ..amount = amount ?? this.amount
      ..categorySlug = categorySlug ?? this.categorySlug
      ..legacyCategoryId = legacyCategoryId
      ..startDate = startDate ?? this.startDate
      ..frequency = frequency?.storageKey ?? this.frequency
      ..accountId = accountId ?? this.accountId
      ..endDate = endDate == _sentinel ? this.endDate : endDate as DateTime?
      ..parentId = parentId == _sentinel ? this.parentId : parentId as int?
      ..beneficiaryId = beneficiaryId == _sentinel
          ? this.beneficiaryId
          : beneficiaryId as int?
      ..receiptPath = receiptPath == _sentinel
          ? this.receiptPath
          : receiptPath as String?;
    return model;
  }

  @override
  ExpenseModel closedOn(DateTime endDate) => copyWith(endDate: endDate);

  @override
  ExpenseModel forkedAt(DateTime startDate, int rootId) => ExpenseModel.create(
    name: name,
    amount: amount,
    categorySlug: categorySlug,
    startDate: startDate,
    frequency: frequencyEnum,
    accountId: accountId,
    beneficiaryId: beneficiaryId,
    parentId: rootId,
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'amount': amount,
      'categorySlug': categorySlug,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'parentId': parentId?.toString(),
      'frequency': frequency,
      'accountId': accountId.toString(),
      'beneficiaryId': beneficiaryId?.toString(),
      'receiptPath': receiptPath,
    };
  }

  @override
  @override
  String get storedFrequency => frequency;

  @override
  Frequency get frequencyEnum => Frequency.fromStorage(frequency);

  @override
  set frequencyEnum(Frequency value) {
    frequency = value.storageKey;
  }
}
