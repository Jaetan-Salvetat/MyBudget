import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/models/loan_model.dart';

final DateTime _fixedNow = DateTime(2026, 6, 15, 9, 30);

void main() {
  group('LoanModel toJson/fromJson', () {
    late LoanModel original;

    setUp(() {
      original = LoanModel(
        id: 42,
        name: 'Prêt immobilier',
        amount: 200000.0,
        accountId: 5,
        lenderName: 'Banque Populaire',
        dayOfMonth: 15,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2044, 1, 1),
        interestRate: 3.5,
        duration: 240,
        repaymentTypeId: 'amortizable',
        deferredMonths: 6,
        insuranceTypeId: 'percentage',
        insuranceValue: 0.36,
        insuranceCalculationModeId: 'remainingCapital',
        notes: 'Résidence principale',
      );
    });

    test('toJson produces camelCase keys with IDs as strings', () {
      final json = original.toJson();

      expect(json['id'], '42');
      expect(json['name'], 'Prêt immobilier');
      expect(json['amount'], 200000.0);
      expect(json['accountId'], '5');
      expect(json['lenderName'], 'Banque Populaire');
      expect(json['dayOfMonth'], 15);
      expect(json['startDate'], '2024-01-01T00:00:00.000');
      expect(json['endDate'], '2044-01-01T00:00:00.000');
      expect(json['interestRate'], 3.5);
      expect(json['duration'], 240);
      expect(json['repaymentTypeId'], 'amortizable');
      expect(json['deferredMonths'], 6);
      expect(json['insuranceTypeId'], 'percentage');
      expect(json['insuranceValue'], 0.36);
      expect(json['insuranceCalculationModeId'], 'remainingCapital');
      expect(json['notes'], 'Résidence principale');
    });

    test('fromJson round-trip preserves all fields', () {
      final json = original.toJson();
      final restored = LoanModel.fromJson(json, now: _fixedNow);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.amount, original.amount);
      expect(restored.accountId, original.accountId);
      expect(restored.lenderName, original.lenderName);
      expect(restored.dayOfMonth, original.dayOfMonth);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
      expect(restored.interestRate, original.interestRate);
      expect(restored.duration, original.duration);
      expect(restored.repaymentTypeId, original.repaymentTypeId);
      expect(restored.deferredMonths, original.deferredMonths);
      expect(restored.insuranceTypeId, original.insuranceTypeId);
      expect(restored.insuranceValue, original.insuranceValue);
      expect(
        restored.insuranceCalculationModeId,
        original.insuranceCalculationModeId,
      );
      expect(restored.notes, original.notes);
    });

    test('fromJson parses legacy snake_case keys', () {
      final legacyJson = {
        'id': 10,
        'name': 'Prêt auto',
        'amount': 15000.0,
        'account_id': 3,
        'lender_name': 'Crédit Mutuel',
        'day_of_month': 5,
        'start_date': '2023-06-01T00:00:00.000',
        'end_date': '2028-06-01T00:00:00.000',
        'interest_rate': 4.2,
        'duration': 60,
        'repayment_type_id': 'amortizable',
        'deferred_months': 0,
        'insurance_type_id': 'fixed',
        'insurance_value': 25.0,
        'insurance_calculation_mode_id': 'initialCapital',
        'notes': null,
      };

      final model = LoanModel.fromJson(legacyJson, now: _fixedNow);

      expect(model.id, 10);
      expect(model.name, 'Prêt auto');
      expect(model.amount, 15000.0);
      expect(model.accountId, 3);
      expect(model.lenderName, 'Crédit Mutuel');
      expect(model.dayOfMonth, 5);
      expect(model.startDate, DateTime(2023, 6, 1));
      expect(model.endDate, DateTime(2028, 6, 1));
      expect(model.interestRate, 4.2);
      expect(model.duration, 60);
      expect(model.repaymentTypeId, 'amortizable');
      expect(model.deferredMonths, 0);
      expect(model.insuranceTypeId, 'fixed');
      expect(model.insuranceValue, 25.0);
      expect(model.insuranceCalculationModeId, 'initialCapital');
      expect(model.notes, isNull);
    });

    test('fromJson uses defaults for missing fields', () {
      final minimalJson = <String, dynamic>{};
      final model = LoanModel.fromJson(minimalJson, now: _fixedNow);

      expect(model.id, 0);
      expect(model.name, '');
      expect(model.amount, 0.0);
      expect(model.accountId, 0);
      expect(model.lenderName, 'Non spécifié');
      expect(model.dayOfMonth, 1);
      expect(model.interestRate, 0.0);
      expect(model.duration, 0);
      expect(model.repaymentTypeId, 'amortizable');
      expect(model.deferredMonths, 0);
      expect(model.insuranceTypeId, 'none');
      expect(model.insuranceValue, 0.0);
      expect(model.insuranceCalculationModeId, 'initialCapital');
      expect(model.notes, isNull);
    });

    test('fromJson with notes null produces null notes', () {
      final json = original.toJson();
      json['notes'] = null;
      final model = LoanModel.fromJson(json, now: _fixedNow);
      expect(model.notes, isNull);
    });
  });
}
