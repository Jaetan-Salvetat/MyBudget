library;

import 'dart:convert';

import 'line_signals.dart' show crc32;
import 'lines.dart';
import 'store_gazetteer.dart' show normalizeStore;

const int storeClassifierBuckets = 1 << 16;
const String storeClassifierOther = '';

int _bucket(String token) => crc32(utf8.encode(token)) % storeClassifierBuckets;

Set<int> ticketFeatures(List<PhysicalLine> lines) {
  final features = <int>{};
  for (final line in lines) {
    final words = normalizeStore(line.text)
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    for (final word in words) {
      features.add(_bucket(word));
    }
    for (var index = 0; index + 1 < words.length; index++) {
      features.add(_bucket('${words[index]} ${words[index + 1]}'));
    }
  }
  return features;
}

class StoreClassifier {
  StoreClassifier({
    required this.classes,
    required this.intercepts,
    required this.weights,
  }) {
    if (classes.length != intercepts.length ||
        classes.length != weights.length) {
      throw StateError(
        'classes, biais et poids doivent avoir la même longueur',
      );
    }
  }

  factory StoreClassifier.fromJson(Map<String, dynamic> data) {
    if (data['buckets'] != storeClassifierBuckets) {
      throw StateError(
        '${data['buckets']} seaux dans le modèle, $storeClassifierBuckets attendus',
      );
    }
    return StoreClassifier(
      classes: (data['classes'] as List<dynamic>).cast<String>(),
      intercepts: [
        for (final value in data['intercepts'] as List<dynamic>)
          (value as num).toDouble(),
      ],
      weights: [
        for (final weight in data['weights'] as List<dynamic>)
          {
            for (final entry in (weight as Map<String, dynamic>).entries)
              int.parse(entry.key): (entry.value as num).toDouble(),
          },
      ],
    );
  }

  final List<String> classes;
  final List<double> intercepts;
  final List<Map<int, double>> weights;

  List<double> scores(List<PhysicalLine> lines) {
    final features = ticketFeatures(lines);
    return [
      for (var index = 0; index < classes.length; index++)
        intercepts[index] +
            features.fold<double>(
              0.0,
              (sum, f) => sum + (weights[index][f] ?? 0.0),
            ),
    ];
  }

  String? predict(List<PhysicalLine> lines) {
    final scored = scores(lines);
    var best = 0;
    for (var index = 1; index < scored.length; index++) {
      if (scored[index] > scored[best]) best = index;
    }
    final store = classes[best];
    return store == storeClassifierOther ? null : store;
  }

  Map<String, dynamic> toJson() => {
    'buckets': storeClassifierBuckets,
    'classes': classes,
    'intercepts': intercepts,
    'weights': [
      for (final weight in weights)
        {for (final key in weight.keys.toList()..sort()) '$key': weight[key]},
    ],
  };
}
