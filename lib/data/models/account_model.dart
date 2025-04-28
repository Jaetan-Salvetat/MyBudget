import 'package:hive/hive.dart';

import '../../domain/entities/account.dart';

part 'account_model.g.dart';

@HiveType(typeId: 2)
class AccountModel extends Account {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double balance;
  const AccountModel({
    required this.id,
    required this.name,
    required this.balance,
  }) : super(id: id, name: name, balance: balance);

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      name: json['name'],
      balance: json['balance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
    };
  }
}