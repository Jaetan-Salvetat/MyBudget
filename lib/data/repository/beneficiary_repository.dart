import 'package:mybudget/data/model/beneficiary_model.dart';
import 'package:mybudget/objectbox.g.dart';

class BeneficiaryRepository {
  BeneficiaryRepository(Store store) : _box = Box<BeneficiaryModel>(store);

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
