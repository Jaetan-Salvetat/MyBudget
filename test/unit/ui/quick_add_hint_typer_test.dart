import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_hint_typer.dart';

void main() {
  test('types the first phrase one character at a time', () {
    fakeAsync((async) {
      final typer = QuickAddHintTyper();
      addTearDown(typer.dispose);
      typer.start();

      async.elapse(QuickAddHintTyper.keyStroke * 3);

      expect(
        typer.value,
        QuickAddHintTyper.phrases.first.substring(0, 3),
      );
    });
  });

  test('erases, then moves on to the next phrase', () {
    fakeAsync((async) {
      final typer = QuickAddHintTyper();
      addTearDown(typer.dispose);
      typer.start();

      final first = QuickAddHintTyper.phrases.first;
      async.elapse(QuickAddHintTyper.keyStroke * first.length);
      expect(typer.value, first);

      async.elapse(
        QuickAddHintTyper.holdPhrase +
            QuickAddHintTyper.backspace * first.length +
            QuickAddHintTyper.betweenPhrases +
            QuickAddHintTyper.keyStroke * 2,
      );

      expect(typer.value, isNotEmpty);
      expect(QuickAddHintTyper.phrases[1], startsWith(typer.value));
    });
  });

  test('stops for good once the user takes over', () {
    fakeAsync((async) {
      final typer = QuickAddHintTyper();
      addTearDown(typer.dispose);
      typer.start();
      async.elapse(QuickAddHintTyper.keyStroke * 4);

      typer.stop();
      async.elapse(const Duration(seconds: 5));

      expect(typer.value, isEmpty);

      typer.start();
      async.elapse(const Duration(seconds: 5));

      expect(typer.value, isEmpty);
    });
  });

  test('freezing shows the first phrase without ever moving', () {
    fakeAsync((async) {
      final typer = QuickAddHintTyper();
      addTearDown(typer.dispose);

      typer.freeze();
      async.elapse(const Duration(seconds: 5));

      expect(typer.value, QuickAddHintTyper.phrases.first);
    });
  });
}
