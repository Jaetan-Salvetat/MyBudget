import 'package:flutter/material.dart';
import 'package:mybudget/core/domain/loan.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/models/loan_model.dart';

/// ViewModel pour l'édition de prêt
/// Responsabilité : Gérer l'état du formulaire d'édition avec pré-remplissage
class LoanEditViewModel extends ChangeNotifier {
  final Loan initialLoan;

  // Contrôleurs pour champs MODIFIABLES uniquement
  late TextEditingController nameController;
  late TextEditingController lenderController;
  late TextEditingController insuranceValueController;

  // Variables d'état pour champs modifiables
  int _selectedAccountId;
  int _dayOfMonth;
  LoanInsuranceType _insuranceType;
  InsuranceCalculationMode _insuranceCalcMode;

  // Constructeur avec pré-remplissage des valeurs existantes
  LoanEditViewModel(this.initialLoan)
      : _selectedAccountId = initialLoan.accountId,
        _dayOfMonth = initialLoan.dayOfMonth,
        _insuranceType = initialLoan.insuranceType,
        _insuranceCalcMode = initialLoan.insuranceCalculationMode {
    // Initialiser les contrôleurs avec les valeurs existantes
    nameController = TextEditingController(text: initialLoan.name);
    lenderController = TextEditingController(text: initialLoan.lenderName);
    insuranceValueController = TextEditingController(
      text: initialLoan.insuranceValue > 0
          ? initialLoan.insuranceValue.toString()
          : '',
    );

    // Ajouter les listeners pour notifyListeners()
    nameController.addListener(notifyListeners);
    lenderController.addListener(notifyListeners);
    insuranceValueController.addListener(notifyListeners);
  }

  // ========== Getters pour champs LECTURE SEULE (depuis initialLoan) ==========

  double get capital => initialLoan.amount;
  DateTime get signatureDate => initialLoan.startDate;
  DateTime get endDate => initialLoan.endDate;
  int get duration => initialLoan.duration;
  double get interestRate => initialLoan.interestRate;
  LoanRepaymentType get repaymentType => initialLoan.repaymentType;
  int get deferredMonths => initialLoan.deferredMonths;

  // ========== Getters pour champs MODIFIABLES ==========

  String get name => nameController.text.trim();
  String get lenderName => lenderController.text.trim();
  int get selectedAccountId => _selectedAccountId;
  int get dayOfMonth => _dayOfMonth;
  LoanInsuranceType get insuranceType => _insuranceType;
  InsuranceCalculationMode get insuranceCalcMode => _insuranceCalcMode;

  double get insuranceValue {
    return double.tryParse(
          insuranceValueController.text.replaceAll(',', '.'),
        ) ??
        0.0;
  }

  // ========== Calculs pour prévisualisation ==========

  /// Calcul de l'assurance mensuelle (pour affichage en temps réel)
  double get monthlyInsurancePayment {
    if (_insuranceType == LoanInsuranceType.none || insuranceValue <= 0) {
      return 0.0;
    }

    if (_insuranceType == LoanInsuranceType.fixed) {
      return insuranceValue;
    }

    // Pourcentage : calculer selon le mode (CI ou CRD)
    // Pour la prévisualisation, on utilise le capital initial
    final baseCapital = _insuranceCalcMode == InsuranceCalculationMode.initialCapital
        ? capital
        : capital; // Simplification pour l'aperçu

    return (baseCapital * (insuranceValue / 100)) / 12;
  }

  // ========== Validation ==========

  bool get isValid {
    return name.isNotEmpty &&
        lenderName.isNotEmpty &&
        _selectedAccountId > 0;
  }

  // ========== Setters ==========

  void setAccountId(int id) {
    _selectedAccountId = id;
    notifyListeners();
  }

  void setDayOfMonth(int day) {
    _dayOfMonth = day.clamp(1, 31);
    notifyListeners();
  }

  void setInsuranceType(LoanInsuranceType type) {
    _insuranceType = type;
    notifyListeners();
  }

  void setInsuranceCalculationMode(InsuranceCalculationMode mode) {
    _insuranceCalcMode = mode;
    notifyListeners();
  }

  // ========== Création du LoanModel mis à jour ==========

  /// Crée un nouveau LoanModel avec les valeurs modifiées
  /// Utilise copyWith() pour ne modifier que les champs éditables
  LoanModel createUpdatedLoanModel() {
    return initialLoan.model.copyWith(
      name: name,
      lenderName: lenderName,
      accountId: _selectedAccountId,
      dayOfMonth: _dayOfMonth,
      insuranceType: _insuranceType,
      insuranceValue: insuranceValue,
      insuranceCalculationMode: _insuranceCalcMode,
    );
  }

  // ========== Cleanup ==========

  @override
  void dispose() {
    nameController.dispose();
    lenderController.dispose();
    insuranceValueController.dispose();
    super.dispose();
  }
}
