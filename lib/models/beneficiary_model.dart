import 'package:objectbox/objectbox.dart';

@Entity()
class BeneficiaryModel {
  @Id()
  int id = 0;

  @Index()
  late String name;

  BeneficiaryModel();

  BeneficiaryModel.create({required this.name});

  BeneficiaryModel copyWith({String? name}) {
    final model =
        BeneficiaryModel()
          ..id = id
          ..name = name ?? this.name;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {'id': id.toString(), 'name': name};
  }

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    final model = BeneficiaryModel()..name = json['name'] ?? '';

    if (json['id'] != null) {
      model.id = int.tryParse(json['id'].toString()) ?? 0;
    }

    return model;
  }
}
