import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/quick_add_exception.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/expense_model.dart';
import 'package:mybudget/models/quick_add_draft_model.dart';
import 'package:mybudget/models/quick_add_submission_model.dart';
import 'package:mybudget/ui/expenses/expenses_provider.dart';
import 'package:mybudget/ui/quick_add/quick_add_provider.dart';
import 'package:mybudget/ui/revenues/revenues_provider.dart';

import 'harness/e2e_harness.dart';
import 'harness/fake_quick_add_engine.dart';

void main() {
  late E2EHarness app;
  late int accountId;

  final DateTime now = E2EHarness.defaultNow;

  setUp(() async {
    app = await E2EHarness.start(now: now);
    accountId = app.accounts.add(
      AccountModel.create(name: 'Courant', bank: 'Boursorama'),
    );
    app.container.listen(quickAddProvider, (_, _) {}, fireImmediately: true);
  });

  tearDown(() => app.dispose());

  QuickAddNotifier notifier() => app.container.read(quickAddProvider.notifier);

  QuickAddDraft draft() => app.container.read(quickAddProvider);

  Future<void> type(String input) async {
    notifier().onInputChanged(input);
    await pumpEventQueue();
  }

  group('la lecture de la phrase', () {
    test('remplit le brouillon avec ce que le moteur a compris', () async {
      app.engine.script(
        'café 3€',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
          amount: 3,
        ),
      );

      await type('café 3€');

      expect(draft().name, 'Café');
      expect(draft().amount, 3);
      expect(draft().categorySlug, 'restauration.cafe');
      expect(draft().type, TransactionType.expense);
      expect(draft().isSubmittable, isTrue);
    });

    test('lit le montant sans attendre le moteur', () async {
      notifier().onInputChanged('café 3€');

      expect(draft().amount, 3);
      expect(draft().isStale, isTrue);
    });

    test('une saisie vidée efface le brouillon', () async {
      await type('café 3€');
      notifier().onInputChanged('   ');

      expect(draft().isEmpty, isTrue);
    });

    test('n\'analyse que la dernière frappe', () async {
      app.engine.script(
        'café 3€',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
          amount: 3,
        ),
      );

      notifier().onInputChanged('caf');
      notifier().onInputChanged('café');
      await type('café 3€');

      expect(app.engine.seenInputs, <String>['café 3€']);
    });
  });

  group('quand le moteur échoue', () {
    test('le brouillon porte le message, sans perdre le montant', () async {
      app.engine.failWith(
        const QuickAddEngineUnavailableException(
          message: 'Moteur indisponible',
        ),
      );

      await type('café 3€');

      expect(draft().analysisError, 'Moteur indisponible');
      expect(draft().amount, 3);
    });

    test('une erreur inconnue devient le message générique', () async {
      app.engine.failWith(StateError('boom'));

      await type('café 3€');

      expect(draft().analysisError, QuickAddNotifier.unreadInputMessage);
    });
  });

  group('l\'envoi', () {
    Future<QuickAddSubmission> submitCoffee() async {
      app.engine.script(
        'café 3€',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
          amount: 3,
        ),
      );
      await type('café 3€');
      return notifier().submit(accountId);
    }

    test('crée la dépense sur le compte choisi', () async {
      final QuickAddSubmission submission = await submitCoffee();

      final ExpenseModel created = app.expenses.table.all.single;

      expect(submission.type, TransactionType.expense);
      expect(created.name, 'Café');
      expect(created.amount, 3);
      expect(created.categorySlug, 'restauration.cafe');
      expect(created.accountId, accountId);
      expect(created.frequencyEnum, Frequency.oneTime);
    });

    test('horodate la dépense du jour à l\'heure courante', () async {
      await submitCoffee();

      expect(app.expenses.table.all.single.startDate, now);
    });

    test('vide le brouillon', () async {
      await submitCoffee();

      expect(draft().isEmpty, isTrue);
    });

    test('crée un revenu quand la phrase en est un', () async {
      app.engine.script(
        'prime 500€',
        const ScriptedClassification(
          categorySlug: 'salaire.prime',
          name: 'Prime',
          amount: 500,
          type: TransactionType.income,
        ),
      );
      await type('prime 500€');

      final QuickAddSubmission submission = await notifier().submit(accountId);

      expect(submission.type, TransactionType.income);
      expect(app.revenues.table.all.single.name, 'Prime');
      expect(app.expenses.table.all, isEmpty);
    });

    test('refuse une phrase sans montant', () async {
      app.engine.script(
        'café',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
        ),
      );
      await type('café');

      expect(
        () => notifier().submit(accountId),
        throwsA(isA<QuickAddNoAmountException>()),
      );
    });

    test(
      'n\'attend pas le debounce : l\'analyse est réglée à l\'envoi',
      () async {
        app.engine.script(
          'café 3€',
          const ScriptedClassification(
            categorySlug: 'restauration.cafe',
            name: 'Café',
            amount: 3,
          ),
        );
        notifier().onInputChanged('café 3€');

        await notifier().submit(accountId);

        expect(app.expenses.table.all.single.name, 'Café');
      },
    );

    test('range dans « divers.autre » ce qui n\'a pas de catégorie', () async {
      app.engine.failWith(StateError('boom'));
      await type('truc 12€');

      await notifier().submit(accountId);

      expect(
        app.expenses.table.all.single.categorySlug,
        QuickAddDraft.uncategorizedSlug,
      );
    });
  });

  group('l\'annulation', () {
    test('retire la dépense tout juste créée', () async {
      app.engine.script(
        'café 3€',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
          amount: 3,
        ),
      );
      await type('café 3€');
      final QuickAddSubmission submission = await notifier().submit(accountId);

      await notifier().undo(submission);

      expect(app.expenses.table.all, isEmpty);
      expect(await app.container.read(expenseProvider.future), isEmpty);
    });

    test('retire le revenu tout juste créé', () async {
      app.engine.script(
        'prime 500€',
        const ScriptedClassification(
          categorySlug: 'salaire.prime',
          name: 'Prime',
          amount: 500,
          type: TransactionType.income,
        ),
      );
      await type('prime 500€');
      final QuickAddSubmission submission = await notifier().submit(accountId);

      await notifier().undo(submission);

      expect(app.revenues.table.all, isEmpty);
      expect(await app.container.read(revenueProvider.future), isEmpty);
    });
  });

  group('la mémoire de catégorie', () {
    test('retient la correction et la rejoue à la saisie suivante', () async {
      app.engine.script(
        'monoprix 24€',
        const ScriptedClassification(
          categorySlug: 'alimentation.courses',
          name: 'Monoprix',
          amount: 24,
          categoryConfidence: 0.4,
        ),
      );

      await type('monoprix 24€');
      notifier().selectCategory('logement.services');
      await notifier().submit(accountId);

      await type('monoprix 24€');

      expect(draft().categorySlug, 'logement.services');
      expect(draft().categoryConfidence, 1.0);
    });

    test('une catégorie choisie à la main est tenue pour sûre', () async {
      app.engine.script(
        'monoprix 24€',
        const ScriptedClassification(
          categorySlug: 'alimentation.courses',
          name: 'Monoprix',
          amount: 24,
          categoryConfidence: 0.3,
        ),
      );
      await type('monoprix 24€');
      expect(draft().isCategoryUncertain, isTrue);

      notifier().selectCategory('logement.services');

      expect(draft().isCategoryUncertain, isFalse);
    });

    test('la correction est datée de l\'horloge injectée', () async {
      app.engine.script(
        'monoprix 24€',
        const ScriptedClassification(
          categorySlug: 'alimentation.courses',
          name: 'Monoprix',
          amount: 24,
        ),
      );
      await type('monoprix 24€');

      notifier().selectCategory('logement.services');

      expect(app.categoryMemory.table.all.single.updatedAt, now);
    });
  });

  group('les choix épinglés', () {
    test('une date choisie survit à une nouvelle analyse', () async {
      app.engine.script(
        'café 3€',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
          amount: 3,
        ),
      );
      await type('café 3€');

      notifier().selectDate(DateTime(2026, 6, 10));
      await type('café 3€');

      expect(draft().date, DateTime(2026, 6, 10));
      expect(draft().isDatePinned, isTrue);
    });

    test('une fréquence choisie survit à une nouvelle analyse', () async {
      app.engine.script(
        'loyer 900€',
        const ScriptedClassification(
          categorySlug: 'logement.loyer',
          name: 'Loyer',
          amount: 900,
        ),
      );
      await type('loyer 900€');

      notifier().selectFrequency(Frequency.monthly);
      await type('loyer 900€');

      expect(draft().frequency, Frequency.monthly);
    });

    test('la date épinglée devient la date de la dépense', () async {
      app.engine.script(
        'café 3€',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
          amount: 3,
        ),
      );
      await type('café 3€');
      notifier().selectDate(DateTime(2026, 6, 10));

      await notifier().submit(accountId);

      expect(app.expenses.table.all.single.startDate, DateTime(2026, 6, 10));
    });
  });

  group('l\'horloge', () {
    test(
      'le moteur lit la phrase à la date injectée, pas à celle du jour',
      () async {
        app.engine.script(
          'café 3€ hier',
          const ScriptedClassification(
            categorySlug: 'restauration.cafe',
            name: 'Café',
            amount: 3,
          ),
        );

        await type('café 3€ hier');

        expect(draft().date, DateTime(2026, 6, 14));
      },
    );
  });

  group('le compte de saisie', () {
    test('l\'horloge injectée gouverne aussi le repli sans date', () async {
      expect(app.container.read(clockProvider)(), now);
    });

    test('la dépense atterrit sur le compte passé à l\'envoi', () async {
      final int livret = app.accounts.add(
        AccountModel.create(name: 'Livret', bank: 'Boursorama'),
      );
      app.engine.script(
        'café 3€',
        const ScriptedClassification(
          categorySlug: 'restauration.cafe',
          name: 'Café',
          amount: 3,
        ),
      );
      await type('café 3€');

      await notifier().submit(livret);

      expect(app.expenses.table.all.single.accountId, livret);
    });
  });
}
