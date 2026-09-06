import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/loan_event_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/loans/loans_provider.dart';
import 'package:mybudget/ui/onboarding/onboarding_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';
import 'package:mybudget/ui/transfers/transfers_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockRevenueRepository extends Mock implements RevenueRepository {}

class MockLoanRepository extends Mock implements LoanRepository {}

class MockLoanEventRepository extends Mock implements LoanEventRepository {}

class MockTransferRepository extends Mock implements TransferRepository {}

class _FakeAccount extends Fake implements AccountModel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAccountRepository accountRepository;
  late MockExpenseRepository expenseRepository;
  late MockRevenueRepository revenueRepository;
  late MockLoanRepository loanRepository;
  late MockLoanEventRepository loanEventRepository;
  late MockTransferRepository transferRepository;

  setUpAll(() => registerFallbackValue(_FakeAccount()));

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.init();

    accountRepository = MockAccountRepository();
    expenseRepository = MockExpenseRepository();
    revenueRepository = MockRevenueRepository();
    loanRepository = MockLoanRepository();
    loanEventRepository = MockLoanEventRepository();
    transferRepository = MockTransferRepository();

    when(() => accountRepository.getAll()).thenReturn([]);
    when(() => accountRepository.add(any())).thenReturn(1);
    when(() => expenseRepository.getActive()).thenReturn([]);
    when(() => revenueRepository.getActive()).thenReturn([]);
    when(() => loanRepository.getAll()).thenReturn([]);
    when(() => loanEventRepository.getAll()).thenReturn([]);
    when(() => transferRepository.getActive()).thenReturn([]);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(accountRepository),
        expenseRepositoryProvider.overrideWithValue(expenseRepository),
        revenueRepositoryProvider.overrideWithValue(revenueRepository),
        loanRepositoryProvider.overrideWithValue(loanRepository),
        loanEventRepositoryProvider.overrideWithValue(loanEventRepository),
        transferRepositoryProvider.overrideWithValue(transferRepository),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  Future<void> warmUp(ProviderContainer container) async {
    await container.read(expenseProvider.future);
    await container.read(revenueProvider.future);
    await container.read(loanProvider.future);
    await container.read(transferProvider.future);
    container.read(accountProvider);
  }

  test('la page courante suit le PageView', () {
    final container = makeContainer();

    expect(container.read(onboardingProvider), 0);

    container.read(onboardingProvider.notifier).onPageChanged(2);

    expect(container.read(onboardingProvider), 2);
  });

  test('terminer crée le compte saisi et clôt le premier lancement', () async {
    final container = makeContainer();
    await warmUp(container);

    expect(PreferencesService.isFirstLaunch(), isTrue);

    await container
        .read(onboardingProvider.notifier)
        .complete(accountName: 'Compte courant', bank: 'Boursorama');

    final created =
        verify(() => accountRepository.add(captureAny())).captured.single
            as AccountModel;

    expect(created.name, 'Compte courant');
    expect(created.bank, 'Boursorama');
    expect(PreferencesService.isFirstLaunch(), isFalse);
  });

  test(
    'le premier lancement reste ouvert si le compte ne peut pas être créé',
    () async {
      when(() => accountRepository.add(any())).thenThrow(StateError('boum'));

      final container = makeContainer();
      await warmUp(container);

      await expectLater(
        container
            .read(onboardingProvider.notifier)
            .complete(accountName: 'Compte courant', bank: ''),
        throwsStateError,
      );

      expect(PreferencesService.isFirstLaunch(), isTrue);
    },
  );
}
