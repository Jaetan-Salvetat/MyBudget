import 'package:mybudget/core/contracts/stored_frequency.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/utils/json_fields.dart';
import 'package:objectbox/objectbox.dart';

const _sentinel = Object();

@Entity()
class TransferModel implements StoredFrequency {
  TransferModel();

  TransferModel.create({
    required this.name,
    required this.amount,
    required this.fromAccountId,
    required this.toAccountId,
    required this.startDate,
    required Frequency frequency,
    this.endDate,
    this.parentId,
  }) {
    this.frequency = frequency.storageKey;
  }

  factory TransferModel.fromJson(
    Map<String, dynamic> json, {
    required DateTime now,
  }) {
    final model = TransferModel()
      ..id = json.readInt('id', 0)
      ..name = json.readString('name', '')
      ..amount = json.readDouble('amount', 0)
      ..startDate = json.readFirstDate(const ['startDate', 'date']) ?? now
      ..endDate = json.readOptionalDate('endDate')
      ..parentId = json.readOptionalInt('parentId')
      ..frequencyEnum = Frequency.fromStorage(
        json.readString('frequency', Frequency.monthly.storageKey),
      )
      ..fromAccountId = json.readInt('fromAccountId', 0)
      ..toAccountId = json.readInt('toAccountId', 0);
    return model;
  }
  @Id()
  int id = 0;

  @Index()
  late String name;

  late double amount;

  late int fromAccountId;

  late int toAccountId;

  @Property(uid: 1221948770519669890)
  late DateTime startDate;

  @Property()
  DateTime? endDate;

  int? parentId;

  late String frequency;

  TransferModel copyWith({
    String? name,
    double? amount,
    int? fromAccountId,
    int? toAccountId,
    DateTime? startDate,
    Frequency? frequency,
    Object? endDate = _sentinel,
    Object? parentId = _sentinel,
  }) {
    final model = TransferModel()
      ..id = id
      ..name = name ?? this.name
      ..amount = amount ?? this.amount
      ..fromAccountId = fromAccountId ?? this.fromAccountId
      ..toAccountId = toAccountId ?? this.toAccountId
      ..startDate = startDate ?? this.startDate
      ..frequency = frequency?.storageKey ?? this.frequency
      ..endDate = endDate == _sentinel ? this.endDate : endDate as DateTime?
      ..parentId = parentId == _sentinel ? this.parentId : parentId as int?;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'amount': amount,
      'fromAccountId': fromAccountId.toString(),
      'toAccountId': toAccountId.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'parentId': parentId?.toString(),
      'frequency': frequency,
    };
  }

  @override
  String get storedFrequency => frequency;

  double get monthlyAmount => switch (frequencyEnum) {
    Frequency.annual => amount / 12,
    Frequency.oneTime => 0.0,
    Frequency.monthly => amount,
  };

  bool isOutgoingFrom(int accountId) => fromAccountId == accountId;

  bool isIncomingTo(int accountId) => toAccountId == accountId;

  @override
  Frequency get frequencyEnum => Frequency.fromStorage(frequency);

  @override
  set frequencyEnum(Frequency value) {
    frequency = value.storageKey;
  }
}
