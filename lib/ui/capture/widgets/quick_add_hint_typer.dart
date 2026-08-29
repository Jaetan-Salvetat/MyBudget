import 'dart:async';

import 'package:flutter/foundation.dart';

/// Types the example phrases into the empty field, one at a time. It is the
/// only place that can show what the model takes, and it says it better than
/// a row of chips. Stops for good at the first focus.
class QuickAddHintTyper extends ChangeNotifier
    implements ValueListenable<String> {
  static const List<String> phrases = [
    'courses carrefour 42',
    '20 balles à ma sœur',
    'salaire 2100',
  ];

  static const Duration keyStroke = Duration(milliseconds: 55);
  static const Duration backspace = Duration(milliseconds: 26);
  static const Duration holdPhrase = Duration(milliseconds: 1400);
  static const Duration betweenPhrases = Duration(milliseconds: 380);

  String _value = '';
  int _phrase = 0;
  int _cursor = 0;
  bool _deleting = false;
  bool _stopped = false;
  Timer? _next;

  @override
  String get value => _value;

  void start() {
    if (_stopped || _next != null) return;
    _schedule(keyStroke);
  }

  /// Freezes on the first phrase : the examples still read, nothing moves.
  void freeze() {
    if (_stopped) return;
    _stopped = true;
    _next?.cancel();
    _next = null;
    _set(phrases.first);
  }

  /// The user took over : the field hands its hint back to the static one.
  void stop() {
    if (_stopped && _value.isEmpty) return;
    _stopped = true;
    _next?.cancel();
    _next = null;
    _set('');
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  void _schedule(Duration delay) {
    _next = Timer(delay, _tick);
  }

  void _tick() {
    _next = null;
    if (_stopped) return;

    final word = phrases[_phrase];
    _cursor += _deleting ? -1 : 1;
    _set(word.substring(0, _cursor));

    if (!_deleting && _cursor == word.length) {
      _deleting = true;
      _schedule(holdPhrase);
      return;
    }
    if (_deleting && _cursor == 0) {
      _deleting = false;
      _phrase = (_phrase + 1) % phrases.length;
      _schedule(betweenPhrases);
      return;
    }

    _schedule(_deleting ? backspace : keyStroke);
  }

  void _set(String value) {
    if (_value == value) return;
    _value = value;
    notifyListeners();
  }
}
