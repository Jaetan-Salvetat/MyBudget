import 'package:objectbox/objectbox.dart';
import 'package:mybudget/core/enums/frequency.dart';

@Entity()
class TransferModel {
  @Id()
  int id = 0;

  @Index()
  late String name;

  late double amount;

  late int sourceAccountId;

  late int destinationAccountId;

  @Property()
  late DateTime date;

  late String frequencyString;

  bool isAutomatic = true;

  TransferModel();

  TransferModel.create({
    required this.name,
    required this.amount,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.date,
    required this.frequencyString,
  });

  Frequency get frequency {
    return Frequency.values.firstWhere(
      (f) => f.name == frequencyString,
      orElse: () => Frequency.monthly,
    );
  }
}
