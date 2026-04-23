import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/repositories/transfer_repository.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/ui/transfers/transfers_provider.dart';

class MockTransferRepository extends Mock implements TransferRepository {}

class FakeTransferModel extends Fake implements TransferModel {}

void main() {
  late MockTransferRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeTransferModel());
  });

  setUp(() {
    mockRepo = MockTransferRepository();
    when(() => mockRepo.getAll()).thenReturn([]);
    when(() => mockRepo.getActive()).thenReturn([]);
  });

  ProviderContainer makeContainer({List<TransferModel> transfers = const []}) {
    when(() => mockRepo.getAll()).thenReturn(transfers);
    when(() => mockRepo.getActive()).thenReturn(transfers);
    return ProviderContainer(
      overrides: [
        transferRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  TransferModel makeTransfer({
    int id = 0,
    String name = 'Virement',
    double amount = 500,
    int fromAccountId = 1,
    int toAccountId = 2,
    String frequency = 'Mensuel',
  }) {
    return TransferModel.create(
      name: name,
      amount: amount,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      startDate: DateTime(2024, 6, 15),
      frequency: frequency,
    )..id = id;
  }

  group('TransferNotifier build', () {
    test('should load transfers as Transfer entities', () async {
      final container = makeContainer(
        transfers: [makeTransfer(id: 1, name: 'Test')],
      );
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final transfers = container.read(transferProvider).value!;
      expect(transfers.length, 1);
      expect(transfers.first.name, 'Test');
      expect(transfers.first.id, 1);
    });

    test('should return empty list when no transfers', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final transfers = container.read(transferProvider).value!;
      expect(transfers, isEmpty);
    });
  });

  group('TransferNotifier CRUD', () {
    test('addTransfer should call repo.add and refresh state', () async {
      when(() => mockRepo.add(any())).thenReturn(1);
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final model = makeTransfer(name: 'Nouveau');
      await container.read(transferProvider.notifier).addTransfer(model);

      verify(() => mockRepo.add(model)).called(1);
    });

    test('updateTransfer with name-only change updates entire chain', () async {
      final existing = makeTransfer(id: 1);
      when(() => mockRepo.get(1)).thenReturn(existing);
      when(() => mockRepo.getChain(1)).thenReturn([existing]);
      when(() => mockRepo.update(any())).thenReturn(1);
      final container = makeContainer(
        transfers: [existing],
      );
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final updated = makeTransfer(id: 1, name: 'Modifié');
      await container.read(transferProvider.notifier).updateTransfer(updated);

      verify(() => mockRepo.getChain(1)).called(1);
      verify(() => mockRepo.update(any())).called(1);
    });

    test('updateTransfer with structural change closes old and creates new', () async {
      final existing = makeTransfer(id: 1, amount: 500);
      when(() => mockRepo.get(1)).thenReturn(existing);
      when(() => mockRepo.update(any())).thenReturn(1);
      when(() => mockRepo.add(any())).thenReturn(2);
      final container = makeContainer(
        transfers: [existing],
      );
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final updated = makeTransfer(id: 1, amount: 600);
      await container.read(transferProvider.notifier).updateTransfer(updated);

      verify(() => mockRepo.update(any())).called(1);
      verify(() => mockRepo.add(any())).called(1);
    });

    test('deleteTransfer soft deletes recurring transfer', () async {
      final existing = makeTransfer(id: 1, frequency: 'Mensuel');
      when(() => mockRepo.get(1)).thenReturn(existing);
      when(() => mockRepo.update(any())).thenReturn(1);
      final container = makeContainer(
        transfers: [existing],
      );
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      await container.read(transferProvider.notifier).deleteTransfer(1);

      verify(() => mockRepo.update(any())).called(1);
      verifyNever(() => mockRepo.delete(any()));
    });

    test('deleteTransfer hard deletes oneTime transfer', () async {
      final existing = makeTransfer(id: 1, frequency: 'Ponctuel');
      when(() => mockRepo.get(1)).thenReturn(existing);
      when(() => mockRepo.delete(any())).thenReturn(true);
      final container = makeContainer(
        transfers: [existing],
      );
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      await container.read(transferProvider.notifier).deleteTransfer(1);

      verify(() => mockRepo.delete(1)).called(1);
      verifyNever(() => mockRepo.update(any()));
    });
  });

  group('TransferNotifier queries', () {
    test('getTransfersForAccount returns transfers involving account', () async {
      final t1 = makeTransfer(id: 1, fromAccountId: 1, toAccountId: 2);
      final t2 = makeTransfer(id: 2, fromAccountId: 3, toAccountId: 1);
      final t3 = makeTransfer(id: 3, fromAccountId: 3, toAccountId: 4);

      final container = makeContainer(transfers: [t1, t2, t3]);
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final result = container.read(transferProvider.notifier).getTransfersForAccount(1);

      expect(result.length, 2);
      expect(result.map((t) => t.id), containsAll([1, 2]));
    });

    test('getOutgoingTotalForAccount sums outgoing monthly amounts', () async {
      final monthly = makeTransfer(id: 1, fromAccountId: 1, toAccountId: 2, amount: 300);
      final annual = makeTransfer(id: 2, fromAccountId: 1, toAccountId: 3, amount: 1200, frequency: 'Annuel');
      final incoming = makeTransfer(id: 3, fromAccountId: 2, toAccountId: 1, amount: 999);

      final container = makeContainer(transfers: [monthly, annual, incoming]);
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final total = container.read(transferProvider.notifier).getOutgoingTotalForAccount(1);

      expect(total, 400.0);
    });

    test('getIncomingTotalForAccount sums incoming monthly amounts', () async {
      final incoming1 = makeTransfer(id: 1, fromAccountId: 2, toAccountId: 1, amount: 200);
      final incoming2 = makeTransfer(id: 2, fromAccountId: 3, toAccountId: 1, amount: 2400, frequency: 'Annuel');
      final outgoing = makeTransfer(id: 3, fromAccountId: 1, toAccountId: 4, amount: 999);

      final container = makeContainer(transfers: [incoming1, incoming2, outgoing]);
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final total = container.read(transferProvider.notifier).getIncomingTotalForAccount(1);

      expect(total, 400.0);
    });

    test('getMonthlyTransferBalance returns incoming minus outgoing', () async {
      final incoming = makeTransfer(id: 1, fromAccountId: 2, toAccountId: 1, amount: 800);
      final outgoing = makeTransfer(id: 2, fromAccountId: 1, toAccountId: 3, amount: 300);

      final container = makeContainer(transfers: [incoming, outgoing]);
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final balance = container.read(transferProvider.notifier).getMonthlyTransferBalance(1);

      expect(balance, 500.0);
    });

    test('getMonthlyTransferBalance returns negative when more outgoing', () async {
      final outgoing = makeTransfer(id: 1, fromAccountId: 1, toAccountId: 2, amount: 1000);
      final incoming = makeTransfer(id: 2, fromAccountId: 3, toAccountId: 1, amount: 200);

      final container = makeContainer(transfers: [outgoing, incoming]);
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final balance = container.read(transferProvider.notifier).getMonthlyTransferBalance(1);

      expect(balance, -800.0);
    });

    test('getMonthlyTransferBalance returns 0 when no transfers for account', () async {
      final transfer = makeTransfer(id: 1, fromAccountId: 5, toAccountId: 6, amount: 100);

      final container = makeContainer(transfers: [transfer]);
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final balance = container.read(transferProvider.notifier).getMonthlyTransferBalance(1);

      expect(balance, 0.0);
    });

    test('getTransfersForAccount returns empty list for unknown account', () async {
      final container = makeContainer(
        transfers: [makeTransfer(fromAccountId: 1, toAccountId: 2)],
      );
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final result = container.read(transferProvider.notifier).getTransfersForAccount(99);

      expect(result, isEmpty);
    });

    test('getClosedTransfers returns closed entries', () async {
      final closed = TransferModel.create(
        name: 'Ancien virement',
        amount: 300,
        fromAccountId: 1,
        toAccountId: 2,
        startDate: DateTime(2024, 1, 15),
        frequency: 'Mensuel',
        endDate: DateTime(2024, 6, 15),
      )..id = 1;

      when(() => mockRepo.getClosed()).thenReturn([closed]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(transferProvider.future);

      final result = container.read(transferProvider.notifier).getClosedTransfers();

      expect(result.length, 1);
      expect(result.first.endDate, isNotNull);
    });
  });
}
