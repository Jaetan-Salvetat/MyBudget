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

  String get initials {
    if (name.trim().isEmpty) return '?';

    final parts = name
        .trim()
        .split(RegExp(r'[\s\-]+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    final single = parts.first;
    if (single.length >= 2) {
      return '${single[0].toUpperCase()}${single[1].toLowerCase()}';
    }
    return single[0].toUpperCase();
  }

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
