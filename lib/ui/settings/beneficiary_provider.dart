import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/beneficiary_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'beneficiary_provider.g.dart';

@Riverpod(keepAlive: true)
class BeneficiaryNotifier extends _$BeneficiaryNotifier {
  @override
  Future<List<Beneficiary>> build() async {
    final repo = ref.watch(beneficiaryRepositoryProvider);
    final models = repo.getAll();

    for (final model in models) {
      if (model.color == 0) {
        model.color = Beneficiary.generateColor();
        repo.update(model);
      }
    }

    models.sort((a, b) => a.name.compareTo(b.name));
    return models.map(Beneficiary.fromModel).toList();
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
      final id = repo.add(
        BeneficiaryModel.create(
          name: trimmed,
          color: Beneficiary.generateColor(),
        ),
      );
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
      repo.add(
        BeneficiaryModel.create(
          name: trimmed,
          color: Beneficiary.generateColor(),
        ),
      );
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> renameBeneficiary(int id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Le nom ne peut pas être vide';

    final current = state.value ?? [];
    final duplicate = current.any(
      (b) => b.id != id && b.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) return 'Ce bénéficiaire existe déjà';

    final repo = ref.read(beneficiaryRepositoryProvider);
    try {
      final existing = repo.get(id);
      if (existing == null) return 'Ce bénéficiaire n\'existe plus';

      repo.update(existing.copyWith(name: trimmed));
      ref.invalidateSelf();
      await future;
      return null;
    } catch (e) {
      return e.toString();
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

  int countUsages(int beneficiaryId) => usageCounts()[beneficiaryId] ?? 0;

  /// How many transactions reference each beneficiary, in a single pass over
  /// the transaction repositories so a whole list can be labelled at once.
  Map<int, int> usageCounts() {
    final counts = <int, int>{};
    for (final id in _referencedBeneficiaryIds()) {
      counts.update(id, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Iterable<int> _referencedBeneficiaryIds() sync* {
    for (final expense in ref.read(expenseRepositoryProvider).getAll()) {
      final id = expense.beneficiaryId;
      if (id != null) yield id;
    }
    for (final revenue in ref.read(revenueRepositoryProvider).getAll()) {
      final id = revenue.beneficiaryId;
      if (id != null) yield id;
    }
  }

  Beneficiary? getBeneficiaryById(int id) {
    final repo = ref.read(beneficiaryRepositoryProvider);
    try {
      final model = repo.get(id);
      if (model == null) return null;
      return Beneficiary.fromModel(model);
    } catch (e) {
      return null;
    }
  }
}
