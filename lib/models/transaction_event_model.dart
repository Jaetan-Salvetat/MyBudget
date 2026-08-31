import 'package:mybudget/core/entities/transaction_change_entry.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class TransactionEventModel {
  @Id()
  int id = 0;

  @Index()
  late int rootId;

  late String transactionType;

  late String change;

  String? previousValue;

  String? nextValue;

  late DateTime at;

  TransactionEventModel();

  TransactionEventModel.create({
    required this.rootId,
    required TransactionType type,
    required TransactionChangeEntry entry,
  }) : transactionType = type.name,
       change = entry.change.name,
       previousValue = entry.from,
       nextValue = entry.to,
       at = entry.at;

  TransactionType get typeEnum => TransactionType.values.firstWhere(
    (type) => type.name == transactionType,
    orElse: () => TransactionType.expense,
  );

  TransactionChange get changeEnum => TransactionChange.fromName(change);
}
