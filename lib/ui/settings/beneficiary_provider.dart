import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'beneficiary_provider.g.dart';

@Riverpod(keepAlive: true)
class BeneficiaryNotifier extends _$BeneficiaryNotifier {
  @override
  Future<List<BeneficiaryModel>> build() async {
    final repo = ref.watch(beneficiaryRepositoryProvider);
    final beneficiaries = repo.getAll();
    beneficiaries.sort((a, b) => a.name.compareTo(b.name));
    return beneficiaries;
  }

  Future<int?> createBeneficiary(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final current = state.value ?? [];
    final duplicate = current.any(
      (b) => b.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) return null;

    final repo = ref.read(beneficiaryRepositoryProvider);
    try {
      final id = repo.add(BeneficiaryModel.create(name: trimmed));
      ref.invalidateSelf();
      await future;
      return id;
    } catch (e) {
      return null;
    }
  }

  Future<String?> addBeneficiary(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Le nom ne peut pas être vide';

    final current = state.value ?? [];
    final duplicate = current.any(
      (b) => b.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) return 'Ce bénéficiaire existe déjà';

    final repo = ref.read(beneficiaryRepositoryProvider);
    try {
      repo.add(BeneficiaryModel.create(name: trimmed));
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> updateBeneficiary(BeneficiaryModel beneficiary) async {
    try {
      final repo = ref.read(beneficiaryRepositoryProvider);
      repo.update(beneficiary);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> deleteBeneficiary(int id) async {
    final usageCount = countUsages(id);
    if (usageCount > 0) {
      return 'Ce bénéficiaire est utilisé par $usageCount transaction${usageCount > 1 ? 's' : ''}';
    }

    final repo = ref.read(beneficiaryRepositoryProvider);
    try {
      repo.delete(id);
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  int countUsages(int beneficiaryId) {
    final expenseRepo = ref.read(expenseRepositoryProvider);
    final revenueRepo = ref.read(revenueRepositoryProvider);
    final expenses = expenseRepo
        .getAll()
        .where((e) => e.beneficiaryId == beneficiaryId)
        .length;
    final revenues = revenueRepo
        .getAll()
        .where((r) => r.beneficiaryId == beneficiaryId)
        .length;
    return expenses + revenues;
  }

  BeneficiaryModel? getBeneficiaryById(int id) {
    final repo = ref.read(beneficiaryRepositoryProvider);
    try {
      return repo.get(id);
    } catch (e) {
      return null;
    }
  }
}
