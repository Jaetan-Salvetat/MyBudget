import 'package:mybudget/core/utils/json_fields.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class BeneficiaryModel {
  BeneficiaryModel();

  BeneficiaryModel.create({required this.name, this.color = 0});

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaryModel()
      ..id = json.readInt('id', 0)
      ..name = json.readString('name', '')
      ..color = json.readInt('color', 0);
  }
  @Id()
  int id = 0;

  @Index()
  late String name;

  int color = 0;

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
}
