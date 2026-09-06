import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/ui/capture/widgets/quick_add_hint_typer.dart';

const List<String> _phrases = ['abc', 'de'];

QuickAddHintTyper _typer() {
  final typer = QuickAddHintTyper(phrases: _phrases);
  addTearDown(typer.dispose);

  return typer;
}

void main() {
  test('types the first phrase one character at a time', () {
    fakeAsync((async) {
      final typer = _typer();
      typer.start();

      async.elapse(QuickAddHintTyper.keyStroke * 2);

      expect(typer.value, 'ab');
    });
  });

  test('erases, then moves on to the next phrase', () {
    fakeAsync((async) {
      final typer = _typer();
      typer.start();

      async.elapse(QuickAddHintTyper.keyStroke * 3);
      expect(typer.value, 'abc');

      async.elapse(
        QuickAddHintTyper.holdPhrase +
            QuickAddHintTyper.backspace * 2 +
            QuickAddHintTyper.betweenPhrases,
      );

      expect(typer.value, 'd');
    });
  });

  test('erases down to nothing instead of flashing the resting hint', () {
    fakeAsync((async) {
      final typer = _typer();
      typer.start();

      async.elapse(
        QuickAddHintTyper.keyStroke * 3 +
            QuickAddHintTyper.holdPhrase +
            QuickAddHintTyper.backspace * 2,
      );

      expect(typer.value, isEmpty);
    });
  });

  test('pausing falls back to the resting hint and stops typing', () {
    fakeAsync((async) {
      final typer = _typer();
      typer.start();
      async.elapse(QuickAddHintTyper.keyStroke * 2);

      typer.pause();
      expect(typer.value, QuickAddHintTyper.resting);

      async.elapse(const Duration(seconds: 5));
      expect(typer.value, QuickAddHintTyper.resting);
    });
  });

  test('resumes on the next phrase once the field goes idle again', () {
    fakeAsync((async) {
      final typer = _typer();
      typer.start();
      async.elapse(QuickAddHintTyper.keyStroke * 2);
      expect(typer.value, 'ab');

      typer.pause();
      typer.start();
      async.elapse(QuickAddHintTyper.keyStroke);

      expect(typer.value, 'd');
    });
  });

  test('starting again while running changes nothing', () {
    fakeAsync((async) {
      final typer = _typer();
      typer.start();
      async.elapse(QuickAddHintTyper.keyStroke * 2);

      typer.start();
      async.elapse(QuickAddHintTyper.keyStroke);

      expect(typer.value, 'abc');
    });
  });

  test('cycles through every catalog phrase by default', () {
    final typer = QuickAddHintTyper();
    addTearDown(typer.dispose);

    expect(typer.phrases, hasLength(QuickAddHintTyper.catalog.length));
    expect(typer.phrases, containsAll(QuickAddHintTyper.catalog));
  });

  test('offers a broad set of example phrases', () {
    expect(QuickAddHintTyper.catalog.length, greaterThanOrEqualTo(10));
    expect(
      QuickAddHintTyper.catalog.toSet(),
      hasLength(QuickAddHintTyper.catalog.length),
    );
  });
}
