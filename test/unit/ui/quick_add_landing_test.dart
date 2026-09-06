import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/capture/quick_add_landing.dart';

void main() {
  late QuickAddLandingController controller;

  setUp(() => controller = QuickAddLandingController());
  tearDown(() => controller.dispose());

  test('au repos, la figure du mois suit ce que dit la base', () {
    expect(controller.holdsTheFigure, isFalse);
  });

  test('le tap fige la figure avant même que l\'écriture parte', () {
    controller.arm();

    expect(controller.holdsTheFigure, isTrue);
  });

  test('la figure encaisse une fois le créneau ouvert, pas au tap', () async {
    controller.arm();
    controller.land();

    expect(controller.holdsTheFigure, isTrue);

    await Future<void>.delayed(
      QuickAddLandingController.figureDelay + const Duration(milliseconds: 30),
    );

    expect(controller.holdsTheFigure, isFalse);
  });

  test('un envoi qui échoue rend la figure tout de suite', () {
    controller.arm();
    controller.release();

    expect(controller.holdsTheFigure, isFalse);
  });

  test('une seconde saisie repousse l\'encaissement plutôt que d\'en lancer '
      'deux', () async {
    controller.arm();
    controller.land();
    await Future<void>.delayed(const Duration(milliseconds: 60));

    controller.arm();
    controller.land();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(controller.holdsTheFigure, isTrue);

    await Future<void>.delayed(QuickAddLandingController.figureDelay);

    expect(controller.holdsTheFigure, isFalse);
  });

  test('chaque bascule prévient ce qui écoute, et une seule fois', () {
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.arm();
    controller.arm();
    controller.release();
    controller.release();

    expect(notifications, 2);
  });
}
