import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/exceptions/flag_blocklist_exception.dart';
import 'package:mybudget/core/models/flag_blocklist.dart';

FlagBlocklist parse(String payload) {
  return FlagBlocklist.fromJson(jsonDecode(payload) as Map<String, Object?>);
}

void main() {
  group('FlagBlocklist', () {
    test('ne bloque rien avec une liste vide', () {
      final FlagBlocklist blocklist = parse('{"blocked": []}');

      expect(blocklist.blocks(flagId: 'scan', buildNumber: 42), isFalse);
      expect(blocklist.blockedFlagIds, isEmpty);
    });

    test('bloque toutes les versions quand aucun build n\'est précisé', () {
      final FlagBlocklist blocklist = parse('{"blocked": [{"id": "scan"}]}');

      expect(blocklist.blocks(flagId: 'scan', buildNumber: 1), isTrue);
      expect(blocklist.blocks(flagId: 'scan', buildNumber: 999), isTrue);
    });

    test('ne bloque que les builds énumérés', () {
      final FlagBlocklist blocklist = parse(
        '{"blocked": [{"id": "scan", "builds": [42, 43]}]}',
      );

      expect(blocklist.blocks(flagId: 'scan', buildNumber: 42), isTrue);
      expect(blocklist.blocks(flagId: 'scan', buildNumber: 43), isTrue);
      expect(blocklist.blocks(flagId: 'scan', buildNumber: 44), isFalse);
    });

    test('expose les identifiants bloqués pour vérification', () {
      final FlagBlocklist blocklist = parse(
        '{"blocked": [{"id": "scan"}, {"id": "quickAddAi", "builds": [1]}]}',
      );

      expect(blocklist.blockedFlagIds, <String>['scan', 'quickAddAi']);
    });

    test('ignore un blocage ciblé quand la version est inconnue', () {
      final FlagBlocklist blocklist = parse(
        '{"blocked": [{"id": "scan", "builds": [42]}, {"id": "quickAddAi"}]}',
      );

      expect(blocklist.blocks(flagId: 'scan'), isFalse);
      expect(blocklist.blocks(flagId: 'quickAddAi'), isTrue);
    });

    test('refuse une charge utile sans liste de blocage', () {
      expect(
        () => parse('{}'),
        throwsA(isA<FlagBlocklistMalformedException>()),
      );
    });

    test('refuse une entrée sans identifiant exploitable', () {
      expect(
        () => parse('{"blocked": [{"builds": [1]}]}'),
        throwsA(isA<FlagBlocklistMalformedException>()),
      );
      expect(
        () => parse('{"blocked": [{"id": ""}]}'),
        throwsA(isA<FlagBlocklistMalformedException>()),
      );
    });

    test('refuse des numéros de build qui ne sont pas des entiers', () {
      expect(
        () => parse('{"blocked": [{"id": "scan", "builds": ["42"]}]}'),
        throwsA(isA<FlagBlocklistMalformedException>()),
      );
    });
  });
}
