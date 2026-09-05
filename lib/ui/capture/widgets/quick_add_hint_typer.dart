import 'dart:async';

import 'package:flutter/foundation.dart';

class QuickAddHintTyper extends ChangeNotifier
    implements ValueListenable<String> {
  static const List<String> catalog = [
    'courses carrefour 42',
    '20 balles à ma sœur',
    'salaire 2100',
    'plein d\'essence 68',
    'resto avec léa 34,50',
    'netflix 15,99 tous les mois',
    'café en bas 2,20',
    'loyer 750',
    'pharmacie 12,40',
    'billet de train 39',
    'remboursement mutuelle 28',
    'abonnement salle de sport 29,90',
    'cadeau anniversaire 45',
    'ticket de métro 2,50',
  ];

  static const String resting = 'courses carrefour 42';

  static const Duration keyStroke = Duration(milliseconds: 55);
  static const Duration backspace = Duration(milliseconds: 26);
  static const Duration holdPhrase = Duration(milliseconds: 1400);
  static const Duration betweenPhrases = Duration(milliseconds: 380);

  final List<String> phrases;

  String _value = '';
  int _phrase = 0;
  int _cursor = 0;
  bool _deleting = false;
  bool _running = false;
  Timer? _next;

  QuickAddHintTyper({List<String>? phrases})
    : phrases = phrases ?? (catalog.toList()..shuffle());

  @override
  String get value => _value;

  void start() {
    if (_running) return;

    _running = true;
    _cursor = 0;
    _deleting = false;
    _set('');
    _schedule(keyStroke);
  }

  void pause() {
    if (!_running && _value == resting) return;

    _running = false;
    _next?.cancel();
    _next = null;
    _phrase = (_phrase + 1) % phrases.length;
    _set(resting);
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
    if (!_running) return;

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
