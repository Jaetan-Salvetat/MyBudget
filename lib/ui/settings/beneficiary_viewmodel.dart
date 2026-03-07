import 'package:flutter/material.dart';
import 'package:mybudget/core/repositories/beneficiary_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/models/beneficiary_model.dart';

class BeneficiaryViewModel extends ChangeNotifier {
  final BeneficiaryRepository _beneficiaryRepository;
  final ExpenseRepository _expenseRepository;
  final RevenueRepository _revenueRepository;

  List<BeneficiaryModel> _beneficiaries = [];
  bool _isLoading = false;
  String _error = '';

  List<BeneficiaryModel> get beneficiaries => _beneficiaries;
  bool get isLoading => _isLoading;
  String get error => _error;

  BeneficiaryViewModel(
    this._beneficiaryRepository,
    this._expenseRepository,
    this._revenueRepository,
  ) {
    loadBeneficiaries();
  }

  Future<void> loadBeneficiaries() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _beneficiaries = _beneficiaryRepository.getAll();
      _beneficiaries.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée un bénéficiaire et retourne son id, ou null si erreur.
  /// Utilisé par les formulaires pour créer et lier en une seule action.
  Future<int?> createBeneficiary(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final duplicate = _beneficiaries.any(
      (b) => b.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) return null;

    try {
      final id = _beneficiaryRepository.add(
        BeneficiaryModel.create(name: trimmed),
      );
      await loadBeneficiaries();
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Retourne null si succès, un message d'erreur sinon.
  Future<String?> addBeneficiary(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Le nom ne peut pas être vide';

    final duplicate = _beneficiaries.any(
      (b) => b.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) return 'Ce bénéficiaire existe déjà';

    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _beneficiaryRepository.add(BeneficiaryModel.create(name: trimmed));
      await loadBeneficiaries();
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return _error;
    }
  }

  Future<void> updateBeneficiary(BeneficiaryModel beneficiary) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _beneficiaryRepository.update(beneficiary);
      await loadBeneficiaries();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Tente de supprimer. Retourne un message d'erreur si utilisé, null si succès.
  Future<String?> deleteBeneficiary(int id) async {
    final usageCount = _countUsages(id);
    if (usageCount > 0) {
      return 'Ce bénéficiaire est utilisé par $usageCount transaction${usageCount > 1 ? 's' : ''}';
    }

    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _beneficiaryRepository.delete(id);
      await loadBeneficiaries();
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return _error;
    }
  }

  int _countUsages(int beneficiaryId) {
    final expenses =
        _expenseRepository
            .getAll()
            .where((e) => e.beneficiaryId == beneficiaryId)
            .length;
    final revenues =
        _revenueRepository
            .getAll()
            .where((r) => r.beneficiaryId == beneficiaryId)
            .length;
    return expenses + revenues;
  }

  BeneficiaryModel? getBeneficiaryById(int id) {
    try {
      return _beneficiaryRepository.get(id);
    } catch (e) {
      return null;
    }
  }
}
