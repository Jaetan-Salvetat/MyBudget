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

List<List<double>> probabilities(List<Map<int, double>> rows) => [
  for (final row in rows)
    [for (var role = 0; role < roleNames.length; role++) row[role] ?? 0.0],
];

void main() {
  final known = Gazetteer({'QUICK': 'Quick', 'AUCHAN': 'Auchan'});

  test('un nom connu normalise la ligne désignée', () {
    final lines = [
      line('Burger Restaurant'),
      line('Quick Rochefort'),
      line('x'),
    ];
    final scores = probabilities([
      {},
      {roleStore: 0.9},
      {},
    ]);
    expect(storeOf(lines, scores, gazetteer: known), 'Quick');
  });

  test('une ligne désignée inconnue est rendue telle quelle', () {
    final lines = [line('BOUCHERIE PHILIBERTINE'), line('Quick'), line('x')];
    final scores = probabilities([
      {roleStore: 0.9},
      {},
      {},
    ]);
    expect(storeOf(lines, scores, gazetteer: known), 'BOUCHERIE PHILIBERTINE');
  });

  test('le répertoire ne choisit jamais la ligne', () {
    final lines = [line('Quick'), line('-SP'), line('x')];
    final scores = probabilities([
      {roleStore: 0.2},
      {roleStore: 0.8},
      {},
    ]);
    expect(storeOf(lines, scores, gazetteer: known), '-SP');
  });

  test("sans ligne désignée, aucun nom n'est cherché ailleurs", () {
    final lines = [
      line('STALINGRAD'),
      line('www.auchan.fr'),
      line('LAIT 1,20'),
    ];
    final scores = probabilities([
      {roleStore: 0.3},
      {},
      {roleItemIndex: 0.9},
    ]);
    expect(storeOf(lines, scores, gazetteer: known), isNull);
  });

  test('sans répertoire, la ligne désignée', () {
    final scores = probabilities([
      {roleStore: 0.9},
      {},
    ]);
    expect(storeOf([line('Quick'), line('x')], scores), 'Quick');
  });
}
