import 'package:hive/hive.dart';

import '../../domain/entities/account.dart';

part 'account_model.g.dart';

@HiveType(typeId: 2)
class AccountModel extends Account {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final String bank;

  AccountModel({required this.id, required this.name, required this.bank})
    : super(id: id, name: name, bank: bank);

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(id: json['id'], name: json['name'], bank: json['bank']);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'bank': bank};
  }
}
