import 'package:objectbox/objectbox.dart';
import 'package:mybudget/core/enums/frequency.dart';

@Entity()
class TransferModel {
  @Id()
  int id = 0;

  @Index()
  late String name;

  late double amount;

  late int fromAccountId;

  late int toAccountId;

  @Property()
  late DateTime date;

  late String frequency;

  TransferModel();

  TransferModel.create({
    required this.name,
    required this.amount,
    required this.fromAccountId,
    required this.toAccountId,
    required this.date,
    required this.frequency,
  });

  TransferModel copyWith({
    String? name,
    double? amount,
    int? fromAccountId,
    int? toAccountId,
    DateTime? date,
    String? frequency,
  }) {
    final model =
        TransferModel()
          ..id = id
          ..name = name ?? this.name
          ..amount = amount ?? this.amount
          ..fromAccountId = fromAccountId ?? this.fromAccountId
          ..toAccountId = toAccountId ?? this.toAccountId
          ..date = date ?? this.date
          ..frequency = frequency ?? this.frequency;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'amount': amount,
      'fromAccountId': fromAccountId.toString(),
      'toAccountId': toAccountId.toString(),
      'date': date.toIso8601String(),
      'frequency': frequency,
    };
  }

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    final model =
        TransferModel()
          ..name = json['name'] ?? ''
          ..amount = (json['amount'] ?? 0.0).toDouble()
          ..date =
              json['date'] != null
                  ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
                  : DateTime.now()
          ..frequency = json['frequency'] ?? ''
          ..fromAccountId =
              json['fromAccountId'] != null
                  ? (int.tryParse(json['fromAccountId'].toString()) ?? 0)
                  : 0
          ..toAccountId =
              json['toAccountId'] != null
                  ? (int.tryParse(json['toAccountId'].toString()) ?? 0)
                  : 0;

    if (json['id'] != null) {
      model.id = int.tryParse(json['id'].toString()) ?? 0;
    }

    return model;
  }

  Frequency get frequencyEnum => Frequency.fromString(frequency);

  set frequencyEnum(Frequency value) {
    frequency = value.label;
  }
}
