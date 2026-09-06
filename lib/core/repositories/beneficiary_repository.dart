import 'package:mybudget/models/beneficiary_model.dart';
import 'package:objectbox/objectbox.dart';

class BeneficiaryRepository {
  BeneficiaryRepository(this._box);
  final Box<BeneficiaryModel> _box;

  List<BeneficiaryModel> getAll() {
    return _box.getAll();
  }

  BeneficiaryModel? get(int id) {
    return _box.get(id);
  }

  int add(BeneficiaryModel beneficiary) {
    return _box.put(beneficiary);
  }

  int update(BeneficiaryModel beneficiary) {
    return _box.put(beneficiary);
  }

  bool delete(int id) {
    return _box.remove(id);
  }

  void deleteAll() {
    _box.removeAll();
  }
}
