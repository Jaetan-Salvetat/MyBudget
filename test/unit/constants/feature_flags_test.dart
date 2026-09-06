import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/constants/feature_flags.dart';
import 'package:mybudget/core/models/feature_flag.dart';
import 'package:mybudget/core/models/flag_blocklist.dart';

const String servedBlocklistPath = 'site/public/flags.json';

void main() {
  final Set<String> registeredIds = featureFlags
      .map((FeatureFlag flag) => flag.id)
      .toSet();

  group('registre des fonctionnalités', () {
    test('n\'expose aucun identifiant en double', () {
      expect(registeredIds, hasLength(featureFlags.length));
    });

    test('décrit le risque de chaque fonctionnalité', () {
      for (final FeatureFlag flag in featureFlags) {
        expect(flag.label, isNotEmpty, reason: flag.id);
        expect(flag.description, isNotEmpty, reason: flag.id);
        expect(flag.risk, isNotEmpty, reason: flag.id);
      }
    });
  });

  group('cohérence avec le disjoncteur servi', () {
    test('le serveur ne bloque que des fonctionnalités du registre', () {
      final File served = File(servedBlocklistPath);
      expect(served.existsSync(), isTrue, reason: servedBlocklistPath);

      final FlagBlocklist blocklist = FlagBlocklist.fromJson(
        jsonDecode(served.readAsStringSync()) as Map<String, Object?>,
      );

      for (final String id in blocklist.blockedFlagIds) {
        expect(
          registeredIds,
          contains(id),
          reason:
              '$servedBlocklistPath bloque "$id", absent du registre in-app',
        );
      }
    });
  });
}
