import 'package:flutter/material.dart';
import 'package:mybudget/core/enums/loan_enums.dart';
import 'package:mybudget/models/loan_model.dart';
import 'package:mybudget/utils/loan_calculator.dart';

enum DurationUnit { years, months }

class LoanCreationViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lenderController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController insuranceValueController =
      TextEditingController();

  String _name = '';
  String _lenderName = '';
  double _amount = 0.0;
  int _selectedAccountId = -1;

  DateTime _startDate = DateTime.now();
  int _dayOfMonth = 1;

  int _durationValue = 0;
  DurationUnit _durationUnit = DurationUnit.years;

  double _interestRate = 0.0;

  LoanInsuranceType _insuranceType = LoanInsuranceType.none;
  double _insuranceValue = 0.0;

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
      _amount =
          double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
      notifyListeners();
    });
    durationController.addListener(() {
      _durationValue = int.tryParse(durationController.text) ?? 0;
      notifyListeners();
    });
    rateController.addListener(() {
      _interestRate =
          double.tryParse(rateController.text.replaceAll(',', '.')) ?? 0.0;
      notifyListeners();
    });
    insuranceValueController.addListener(() {
      _insuranceValue =
          double.tryParse(insuranceValueController.text.replaceAll(',', '.')) ??
          0.0;
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
    super.dispose();
  }

  int _currentStep = 0;
  int get currentStep => _currentStep;
  int get totalSteps => 4;

  String get name => _name;
  String get lenderName => _lenderName;
  double get amount => _amount;
  int get selectedAccountId => _selectedAccountId;
  DateTime get startDate => _startDate;
  int get dayOfMonth => _dayOfMonth;
  int get durationValue => _durationValue;
  DurationUnit get durationUnit => _durationUnit;
  double get interestRate => _interestRate;
  LoanInsuranceType get insuranceType => _insuranceType;
  double get insuranceValue => _insuranceValue;

  int get durationInMonths {
    return _durationUnit == DurationUnit.years
        ? _durationValue * 12
        : _durationValue;
  }

  DateTime get calculatedEndDate {
    return _startDate.add(Duration(days: (durationInMonths * 30.44).round()));
  }

  double get monthlyPrincipalPayment {
    return LoanCalculator.calculatePrincipalPayment(
      amount: _amount,
      annualRate: _interestRate,
      durationInMonths: durationInMonths,
    );
  }

  double get monthlyInsurancePayment {
    return LoanCalculator.calculateMonthlyInsurance(
      amount: _amount,
      type: _insuranceType,
      value: _insuranceValue,
    );
  }

  double get totalMonthlyPayment {
    return LoanCalculator.calculateTotalMonthlyPayment(
      amount: _amount,
      annualRate: _interestRate,
      durationInMonths: durationInMonths,
      insuranceType: _insuranceType,
      insuranceValue: _insuranceValue,
    );
  }

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
    return true;
  }

  bool get isValid {
    return isStep1Valid && isStep2Valid && isStep3Valid;
  }

  bool get canGoNext {
    if (_currentStep == 0) return isStep1Valid;
    if (_currentStep == 1) return isStep2Valid;
    if (_currentStep == 2) return isStep3Valid;
    return false;
  }

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

  void setInsuranceType(LoanInsuranceType type) {
    _insuranceType = type;
    notifyListeners();
  }

  LoanModel createLoanModel() {
    return LoanModel.create(
      name: _name,
      amount: _amount,
      lenderName: _lenderName,
      dayOfMonth: _dayOfMonth,
      startDate: _startDate,
      endDate: calculatedEndDate,
      accountId: _selectedAccountId,
      monthlyPayment: totalMonthlyPayment,
      interestRate: _interestRate,
      duration: durationInMonths,
      insuranceType: _insuranceType,
      insuranceValue: _insuranceValue,
    );
  }
}
