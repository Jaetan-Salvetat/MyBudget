import 'dart:convert';

import 'package:receipt_pipeline/receipt_pipeline.dart';
import 'package:test/test.dart';

PhysicalLine line(String text) => PhysicalLine(
  words: [
    for (final token in text.split(' '))
      Word(
        text: token,
        left: 0,
        top: 0,
        right: 10,
        bottom: 10,
        confidence: null,
      ),
  ],
);

int bucket(String token) => crc32(utf8.encode(token)) % storeClassifierBuckets;

StoreClassifier classifier() => StoreClassifier(
  classes: [storeClassifierOther, 'Auchan', 'LIDL'],
  intercepts: [0.5, 0.0, 0.0],
  weights: [
    {},
    {bucket('AUCHAN'): 2.0, bucket('WAAOH'): 1.5},
    {bucket('LIDL'): 2.0},
  ],
);

void main() {
  group('traits', () {
    test('les mots et les bigrammes normalisés du ticket', () {
      final features = ticketFeatures([
        line('www.auchan.fr'),
        line('Caisse 3'),
      ]);
      expect(
        features,
        containsAll([
          bucket('WWW'),
          bucket('AUCHAN'),
          bucket('FR'),
          bucket('WWW AUCHAN'),
        ]),
      );
      expect(features, contains(bucket('CAISSE 3')));
    });

    test('les bigrammes ne traversent pas les lignes', () {
      expect(
        ticketFeatures([line('AUCHAN'), line('PESSAC')]),
        isNot(contains(bucket('AUCHAN PESSAC'))),
      );
    });

    test("un ticket vide n'a pas de trait", () {
      expect(ticketFeatures([]), isEmpty);
    });
  });

  group('prédiction', () {
    test("l'enseigne soutenue par le ticket", () {
      expect(
        classifier().predict([line('STALINGRAD'), line('www.auchan.fr')]),
        'Auchan',
      );
    });

    test('autre quand rien ne soutient une enseigne', () {
      expect(classifier().predict([line('BOUCHERIE PHILIBERTINE')]), isNull);
    });

    test('la plus forte gagne', () {
      final lines = [
        line('www.auchan.fr'),
        line('VOTRE COMPTE WAAOH'),
        line('LIDL'),
      ];
      expect(classifier().predict(lines), 'Auchan');
    });

    test('un ticket vide est autre', () {
      expect(classifier().predict([]), isNull);
    });
  });

  group('sérialisation', () {
    test('aller-retour json', () {
      final data = classifier().toJson();
      expect(data['buckets'], storeClassifierBuckets);
      final loaded = StoreClassifier.fromJson(data);
      expect(loaded.predict([line('LIDL')]), 'LIDL');
      expect(loaded.toJson(), data);
    });

    test('un modèle à un autre nombre de seaux est refusé', () {
      expect(
        () => StoreClassifier.fromJson({
          'buckets': 16,
          'classes': <String>[],
          'intercepts': <double>[],
          'weights': <Map<String, dynamic>>[],
        }),
        throwsStateError,
      );
    });
  });
}
