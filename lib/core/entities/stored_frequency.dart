import 'package:mybudget/core/enums/frequency.dart';

abstract interface class StoredFrequency {
  String get storedFrequency;
  Frequency get frequencyEnum;
  set frequencyEnum(Frequency value);
}
