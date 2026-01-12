import 'package:flutter/material.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/core/enums/loan_types.dart';
import 'package:mybudget/core/services/loan_calculation_service.dart';
import 'package:mybudget/models/loan_model.dart';

enum DurationUnit { years, months }

/// ViewModel pour la création de prêt
/// Responsabilité : Gérer l'état du formulaire multi-étapes
/// Les calculs sont délégués au LoanCalculationService
class LoanCreationViewModel extends ChangeNotifier {
  final LoanCalculationService _calculationService = const LoanCalculationService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController lenderController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController insuranceValueController = TextEditingController();
  final TextEditingController deferredMonthsController = TextEditingController();

  String _name = '';
  String _lenderName = '';
  double _amount = 0.0;
  int _selectedAccountId = -1;

  DateTime _startDate = DateTime.now();
  int _dayOfMonth = 1;

  int _durationValue = 0;
  DurationUnit _durationUnit = DurationUnit.years;

  double _interestRate = 0.0;

  // Nouveaux champs
  LoanRepaymentType _repaymentType = LoanRepaymentType.amortizable;
  int _deferredMonths = 0;
  bool _hasDeferredPeriod = false;

  LoanInsuranceType _insuranceType = LoanInsuranceType.none;
  double _insuranceValue = 0.0;
  InsuranceCalculationMode _insuranceCalcMode = InsuranceCalculationMode.initialCapital;

  LoanCreationViewModel() {
    nameController.addListener(() {
      _name = nameController.text;
      notifyListeners();
    });
    lenderController.addListener(() {
      _lenderName = lenderController.text;
      notifyListeners();
    });
    amountController.addListener(() {
      _amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
      notifyListeners();
    });
    durationController.addListener(() {
      _durationValue = int.tryParse(durationController.text) ?? 0;
      notifyListeners();
    });
    rateController.addListener(() {
      _interestRate = double.tryParse(rateController.text.replaceAll(',', '.')) ?? 0.0;
      notifyListeners();
    });
    insuranceValueController.addListener(() {
      _insuranceValue =
          double.tryParse(insuranceValueController.text.replaceAll(',', '.')) ?? 0.0;
      notifyListeners();
    });
    deferredMonthsController.addListener(() {
      _deferredMonths = int.tryParse(deferredMonthsController.text) ?? 0;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    lenderController.dispose();
    amountController.dispose();
    durationController.dispose();
    rateController.dispose();
    insuranceValueController.dispose();
    deferredMonthsController.dispose();
    super.dispose();
  }

  int _currentStep = 0;
  int get currentStep => _currentStep;
  int get totalSteps => 5; // Ajout d'une étape pour le type de remboursement

  // Getters
  String get name => _name;
  String get lenderName => _lenderName;
  double get amount => _amount;
  int get selectedAccountId => _selectedAccountId;
  DateTime get startDate => _startDate;
  int get dayOfMonth => _dayOfMonth;
  int get durationValue => _durationValue;
  DurationUnit get durationUnit => _durationUnit;
  double get interestRate => _interestRate;
  LoanRepaymentType get repaymentType => _repaymentType;
  int get deferredMonths => _deferredMonths;
  bool get hasDeferredPeriod => _hasDeferredPeriod;
  LoanInsuranceType get insuranceType => _insuranceType;
  double get insuranceValue => _insuranceValue;
  InsuranceCalculationMode get insuranceCalcMode => _insuranceCalcMode;

  int get durationInMonths {
    return _durationUnit == DurationUnit.years ? _durationValue * 12 : _durationValue;
  }

  /// Calcul correct de la date de fin (calendaire, pas approximatif)
  DateTime get calculatedEndDate {
    final months = durationInMonths;
    final years = months ~/ 12;
    final remainingMonths = months % 12;

    return DateTime(
      _startDate.year + years,
      _startDate.month + remainingMonths,
      _startDate.day,
    );
  }

  /// Paiement mensuel de capital (selon le type de prêt)
  double get monthlyPrincipalPayment {
    if (_repaymentType == LoanRepaymentType.inFine) {
      // In fine : que les intérêts
      return (_amount * _interestRate / 100) / 12;
    } else {
      // Amortissable : capital + intérêts
      return _calculationService.calculateCurrentMonthlyPayment(
        repaymentType: _repaymentType,
        amount: _amount,
        interestRate: _interestRate,
        durationInMonths: durationInMonths - _deferredMonths,
        startDate: _startDate,
        currentDate: _startDate,
        deferredMonths: 0,
        insuranceType: LoanInsuranceType.none,
        insuranceValue: 0,
        insuranceCalcMode: InsuranceCalculationMode.initialCapital,
      );
    }
  }

  /// Paiement mensuel d'assurance (calculé selon le mode)
  double get monthlyInsurancePayment {
    if (_insuranceType == LoanInsuranceType.none || _insuranceValue <= 0) {
      return 0.0;
    }

    if (_insuranceType == LoanInsuranceType.fixed) {
      return _insuranceValue;
    }

    // Pourcentage : selon le mode (CI ou CRD)
    // Pour l'aperçu initial, on utilise le capital initial
    final baseCapital = _insuranceCalcMode == InsuranceCalculationMode.initialCapital
        ? _amount
        : _amount; // Au début, c'est la même chose

    return (baseCapital * (_insuranceValue / 100)) / 12;
  }

  /// Mensualité totale
  double get totalMonthlyPayment {
    return monthlyPrincipalPayment + monthlyInsurancePayment;
  }

  // Validation par étape
  bool get isStep1Valid {
    return _name.isNotEmpty &&
        _lenderName.isNotEmpty &&
        _amount > 0 &&
        _selectedAccountId != -1;
  }

  bool get isStep2Valid {
    return durationInMonths > 0 && _interestRate >= 0;
  }

  bool get isStep3Valid {
    return true; // Type de remboursement : toujours valide (valeur par défaut)
  }

  bool get isStep4Valid {
    return true; // Assurance : toujours valide (optionnel)
  }

  bool get isValid {
    return isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid;
  }

  bool get canGoNext {
    if (_currentStep == 0) return isStep1Valid;
    if (_currentStep == 1) return isStep2Valid;
    if (_currentStep == 2) return isStep3Valid;
    if (_currentStep == 3) return isStep4Valid;
    return false;
  }

  // Navigation
  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  // Setters
  void setAccountId(int id) {
    _selectedAccountId = id;
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void setDayOfMonth(int day) {
    _dayOfMonth = day.clamp(1, 31);
    notifyListeners();
  }

  void setDurationUnit(DurationUnit unit) {
    _durationUnit = unit;
    notifyListeners();
  }

  void setRepaymentType(LoanRepaymentType type) {
    _repaymentType = type;
    notifyListeners();
  }

  void toggleDeferredPeriod() {
    _hasDeferredPeriod = !_hasDeferredPeriod;
    if (!_hasDeferredPeriod) {
      _deferredMonths = 0;
      deferredMonthsController.clear();
    }
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

  /// Crée le LoanModel final avec tous les paramètres
  LoanModel createLoanModel() {
    return LoanModel.create(
      name: _name,
      amount: _amount,
      lenderName: _lenderName,
      accountId: _selectedAccountId,
      dayOfMonth: _dayOfMonth,
      startDate: _startDate,
      endDate: calculatedEndDate,
      interestRate: _interestRate,
      duration: durationInMonths,
      repaymentType: _repaymentType,
      deferredMonths: _hasDeferredPeriod ? _deferredMonths : 0,
      insuranceType: _insuranceType,
      insuranceValue: _insuranceValue,
      insuranceCalculationMode: _insuranceCalcMode,
    );
  }
}
