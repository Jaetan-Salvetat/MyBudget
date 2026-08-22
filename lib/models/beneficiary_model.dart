import 'package:objectbox/objectbox.dart';

@Entity()
class BeneficiaryModel {
  @Id()
  int id = 0;

  @Index()
  late String name;

  int color = 0;

  BeneficiaryModel();

  BeneficiaryModel.create({required this.name, this.color = 0});

  BeneficiaryModel copyWith({String? name, int? color}) {
    final model = BeneficiaryModel()
      ..id = id
      ..name = name ?? this.name
      ..color = color ?? this.color;
    return model;
  }

  Map<String, dynamic> toJson() {
    return {'id': id.toString(), 'name': name, 'color': color};
  }

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    final model = BeneficiaryModel()
      ..name = json['name'] ?? ''
      ..color = json['color'] as int? ?? 0;

    if (json['id'] != null) {
      model.id = int.tryParse(json['id'].toString()) ?? 0;
    }

    return model;
  }
}
