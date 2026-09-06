import 'package:objectbox/objectbox.dart';

@Entity(uid: 637957068368109063)
class LegacyCategoryModel {
  @Id()
  int id = 0;

  @Index()
  late String name;

  late String icon;

  int color = 0xFF2196F3;

  LegacyCategoryModel();
}
