import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/data/repository/account_repository.dart';
import 'package:mybudget/data/repository/beneficiary_repository.dart';
import 'package:mybudget/data/repository/category_memory_repository.dart';
import 'package:mybudget/data/repository/category_override_repository.dart';
import 'package:mybudget/data/repository/expense_repository.dart';
import 'package:mybudget/data/repository/legacy_category_repository.dart';
import 'package:mybudget/data/repository/loan_event_repository.dart';
import 'package:mybudget/data/repository/loan_repository.dart';
import 'package:mybudget/data/repository/revenue_repository.dart';
import 'package:mybudget/data/repository/transaction_event_repository.dart';
import 'package:mybudget/data/repository/transfer_repository.dart';
import 'package:mybudget/data/service/data/user_data_eraser.dart';

const String _fichierModele = 'lib/objectbox-model.json';
const String _fichierEffaceur = 'lib/data/service/data/user_data_eraser.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockBeneficiaryRepository extends Mock implements BeneficiaryRepository {}

class MockCategoryMemoryRepository extends Mock
    implements CategoryMemoryRepository {}

class MockCategoryOverrideRepository extends Mock
    implements CategoryOverrideRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockLegacyCategoryRepository extends Mock
    implements LegacyCategoryRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockTransactionEventRepository extends Mock
    implements TransactionEventRepository {}

class MockTransferRepository extends Mock implements TransferRepository {}

Set<String> _depotsAttendus() {
  final Map<String, dynamic> modele =
      jsonDecode(File(_fichierModele).readAsStringSync())
          as Map<String, dynamic>;
  final List<dynamic> entites = modele['entities'] as List<dynamic>;

  return <String>{
    for (final dynamic entite in entites)
      '${((entite as Map<String, dynamic>)['name'] as String).replaceFirst(RegExp(r'Model$'), '')}Repository',
  };
}

void main() {
  late MockAccountRepository comptes;
  late MockBeneficiaryRepository beneficiaires;
  late MockCategoryMemoryRepository memoiresCategorie;
  late MockCategoryOverrideRepository personnalisationsCategorie;
  late MockExpenseRepository depenses;
  late MockLegacyCategoryRepository categoriesHeritees;
  late MockLoanEventRepository evenementsPret;
  late MockLoanRepository prets;
  late MockRevenueRepository revenus;
  late MockTransactionEventRepository evenementsTransaction;
  late MockTransferRepository virements;
  late UserDataEraser effaceur;

  setUp(() {
    comptes = MockAccountRepository();
    beneficiaires = MockBeneficiaryRepository();
    memoiresCategorie = MockCategoryMemoryRepository();
    personnalisationsCategorie = MockCategoryOverrideRepository();
    depenses = MockExpenseRepository();
    categoriesHeritees = MockLegacyCategoryRepository();
    evenementsPret = MockLoanEventRepository();
    prets = MockLoanRepository();
    revenus = MockRevenueRepository();
    evenementsTransaction = MockTransactionEventRepository();
    virements = MockTransferRepository();

    when(() => comptes.deleteAll()).thenReturn(null);
    when(() => beneficiaires.deleteAll()).thenReturn(null);
    when(() => memoiresCategorie.deleteAll()).thenReturn(null);
    when(() => personnalisationsCategorie.deleteAll()).thenReturn(null);
    when(() => depenses.deleteAll()).thenReturn(null);
    when(() => categoriesHeritees.deleteAll()).thenReturn(null);
    when(() => evenementsPret.deleteAll()).thenReturn(null);
    when(() => prets.deleteAll()).thenReturn(null);
    when(() => revenus.deleteAll()).thenReturn(null);
    when(() => evenementsTransaction.deleteAll()).thenReturn(null);
    when(() => virements.deleteAll()).thenReturn(null);

    effaceur = UserDataEraser(
      accounts: comptes,
      beneficiaries: beneficiaires,
      categoryMemories: memoiresCategorie,
      categoryOverrides: personnalisationsCategorie,
      expenses: depenses,
      legacyCategories: categoriesHeritees,
      loanEvents: evenementsPret,
      loans: prets,
      revenues: revenus,
      transactionEvents: evenementsTransaction,
      transfers: virements,
    );
  });

  group("l'effacement des données utilisateur", () {
    test('vide chaque dépôt exactement une fois', () {
      effaceur.eraseAll();

      verify(() => comptes.deleteAll()).called(1);
      verify(() => beneficiaires.deleteAll()).called(1);
      verify(() => memoiresCategorie.deleteAll()).called(1);
      verify(() => personnalisationsCategorie.deleteAll()).called(1);
      verify(() => depenses.deleteAll()).called(1);
      verify(() => categoriesHeritees.deleteAll()).called(1);
      verify(() => evenementsPret.deleteAll()).called(1);
      verify(() => prets.deleteAll()).called(1);
      verify(() => revenus.deleteAll()).called(1);
      verify(() => evenementsTransaction.deleteAll()).called(1);
      verify(() => virements.deleteAll()).called(1);
    });

    test("n'oublie aucune entité persistée", () {
      final String source = File(_fichierEffaceur).readAsStringSync();
      final List<String> oublies = _depotsAttendus()
          .where((String depot) => !source.contains('$depot '))
          .toList()
        ..sort();

      expect(oublies, isEmpty);
    });
  });
}
