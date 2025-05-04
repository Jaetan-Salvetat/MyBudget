import '../../domain/entities/account.dart';

class AccountModel extends Account {
  @override
  final String id;
  @override
  final String name;
  @override
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
