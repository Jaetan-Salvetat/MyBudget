import 'package:objectbox/objectbox.dart';

@Entity()
class AccountModel {
  @Id()
  int id = 0;

  @Index()
  late String name;

  late String bank;

  AccountModel();

  AccountModel.create({required this.name, required this.bank});

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final model =
        AccountModel()
          ..name = json['name'] ?? ''
          ..bank = json['bank'] ?? '';

    if (json['id'] != null) {
      model.id = int.parse(json['id'].toString());
    }

    return model;
  }

  AccountModel copyWith({String? name, String? bank}) {
    final model =
        AccountModel()
          ..id = id
          ..name = name ?? this.name
          ..bank = bank ?? this.bank;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {'id': id.toString(), 'name': name, 'bank': bank};
  }
}
