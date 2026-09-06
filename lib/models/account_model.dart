import 'package:mybudget/core/utils/json_fields.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class AccountModel {
  AccountModel();

  AccountModel.create({required this.name, required this.bank});

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel()
      ..id = json.readInt('id', 0)
      ..name = json.readString('name', '')
      ..bank = json.readString('bank', '');
  }
  @Id()
  int id = 0;

  @Index()
  late String name;

  late String bank;

  AccountModel copyWith({String? name, String? bank}) {
    final model = AccountModel()
      ..id = id
      ..name = name ?? this.name
      ..bank = bank ?? this.bank;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {'id': id.toString(), 'name': name, 'bank': bank};
  }
}
