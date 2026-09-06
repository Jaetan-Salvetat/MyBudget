import 'package:mybudget/core/entities/recurring_transaction.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/utils/json_fields.dart';
import 'package:objectbox/objectbox.dart';

const _sentinel = Object();

@Entity()
class RevenueModel implements RecurringTransaction<RevenueModel> {
  RevenueModel() {
    frequency = Frequency.monthly.storageKey;
  }

  RevenueModel.create({
    required this.name,
    required this.amount,
    required this.startDate,
    required this.accountId,
    required Frequency frequency,
    this.endDate,
    this.parentId,
    this.beneficiaryId,
    this.categorySlug,
  }) {
    this.frequency = frequency.storageKey;
  }

  factory RevenueModel.fromJson(
    Map<String, dynamic> json, {
    required DateTime now,
  }) {
    final model = RevenueModel()
      ..id = json.readInt('id', 0)
      ..name = json.readString('name', '')
      ..amount = json.readDouble('amount', 0)
      ..startDate = json.readFirstDate(const ['startDate', 'date']) ?? now
      ..endDate = json.readOptionalDate('endDate')
      ..parentId = json.readOptionalInt('parentId')
      ..accountId = json.readInt('accountId', 0)
      ..frequencyEnum = Frequency.fromStorage(
        json.readString('frequency', Frequency.monthly.storageKey),
      )
      ..beneficiaryId = json.readOptionalInt('beneficiaryId')
      ..categorySlug = json.readOptionalString('categorySlug');
    return model;
  }
  @override
  @Id()
  int id = 0;

  @Index()
  @override
  late String name;

  @override
  late int accountId;

  @override
  late double amount;

  @override
  @Property(uid: 1213904468792118615)
  late DateTime startDate;

  @Property()
  @override
  DateTime? endDate;

  @override
  int? parentId;

  late String frequency;

  @override
  int? beneficiaryId;

  @Index()
  @override
  String? categorySlug;

  @override
  @override
  String get storedFrequency => frequency;

  @override
  Frequency get frequencyEnum => Frequency.fromStorage(frequency);

  @override
  set frequencyEnum(Frequency value) {
    frequency = value.storageKey;
  }

  RevenueModel copyWith({
    String? name,
    double? amount,
    DateTime? startDate,
    int? accountId,
    Frequency? frequency,
    Object? endDate = _sentinel,
    Object? parentId = _sentinel,
    Object? beneficiaryId = _sentinel,
    String? categorySlug,
  }) {
    final model = RevenueModel()
      ..id = id
      ..name = name ?? this.name
      ..amount = amount ?? this.amount
      ..startDate = startDate ?? this.startDate
      ..accountId = accountId ?? this.accountId
      ..frequency = frequency?.storageKey ?? this.frequency
      ..categorySlug = categorySlug ?? this.categorySlug
      ..endDate = endDate == _sentinel ? this.endDate : endDate as DateTime?
      ..parentId = parentId == _sentinel ? this.parentId : parentId as int?
      ..beneficiaryId = beneficiaryId == _sentinel
          ? this.beneficiaryId
          : beneficiaryId as int?;
    return model;
  }

  @override
  RevenueModel closedOn(DateTime endDate) => copyWith(endDate: endDate);

  @override
  RevenueModel forkedAt(DateTime startDate, int rootId) => RevenueModel.create(
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
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'parentId': parentId?.toString(),
      'accountId': accountId.toString(),
      'frequency': frequency,
      'beneficiaryId': beneficiaryId?.toString(),
      'categorySlug': categorySlug,
    };
  }
}
