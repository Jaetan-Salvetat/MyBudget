import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/components/charts/_paired_column_frames.dart';

const List<FrostedPairedColumnData> _six = <FrostedPairedColumnData>[
  FrostedPairedColumnData(primary: 100, secondary: 50, label: 'A'),
  FrostedPairedColumnData(primary: 200, secondary: 100, label: 'B'),
];

const List<FrostedPairedColumnData> _twelve = <FrostedPairedColumnData>[
  FrostedPairedColumnData(primary: 40, secondary: 20, label: 'Z'),
  FrostedPairedColumnData(primary: 100, secondary: 50, label: 'A'),
  FrostedPairedColumnData(primary: 200, secondary: 100, label: 'B'),
];

void main() {
  group('PairedColumnFrames.of', () {
    test('normalises both series against the shared peak', () {
      final PairedColumnFrames frames = PairedColumnFrames.of(
        _six,
        maxAxisLabels: 12,
      );

      expect(frames[0].primary, 0.5);
      expect(frames[0].secondary, 0.25);
      expect(frames[1].primary, 1);
      expect(
        frames.every((PairedColumnFrame frame) => frame.weight == 1),
        isTrue,
      );
    });

    test('leaves every column flat when nothing has weight', () {
      final PairedColumnFrames frames = PairedColumnFrames.of(
        const <FrostedPairedColumnData>[
          FrostedPairedColumnData(primary: 0, secondary: 0),
        ],
        maxAxisLabels: 12,
      );

      expect(frames[0].primary, 0);
      expect(frames[0].secondary, 0);
    });
  });

  group('PairedColumnFrames.lerp', () {
    test('anchors the two windows on their newest column', () {
      final PairedColumnFrames frames = PairedColumnFrames.lerp(
        PairedColumnFrames.of(_six, maxAxisLabels: 12),
        PairedColumnFrames.of(_twelve, maxAxisLabels: 12),
        0.5,
      );

      expect(frames.length, 3);
      expect(frames.map((PairedColumnFrame frame) => frame.label), <String>[
        'Z',
        'A',
        'B',
      ]);
    });

    test('unfolds an entering column from no width at its final height', () {
      final PairedColumnFrames frames = PairedColumnFrames.lerp(
        PairedColumnFrames.of(_six, maxAxisLabels: 12),
        PairedColumnFrames.of(_twelve, maxAxisLabels: 12),
        0.25,
      );

      expect(frames[0].weight, 0.25);
      expect(frames[0].primary, 0.2);
    });

    test('collapses a leaving column while it keeps its height', () {
      final PairedColumnFrames frames = PairedColumnFrames.lerp(
        PairedColumnFrames.of(_twelve, maxAxisLabels: 12),
        PairedColumnFrames.of(_six, maxAxisLabels: 12),
        0.75,
      );

      expect(frames[0].weight, 0.25);
      expect(frames[0].primary, 0.2);
    });

    test('rescales the columns that stay when the peak moves', () {
      final PairedColumnFrames frames = PairedColumnFrames.lerp(
        PairedColumnFrames.of(const <FrostedPairedColumnData>[
          FrostedPairedColumnData(primary: 100, secondary: 0),
        ], maxAxisLabels: 12),
        PairedColumnFrames.of(const <FrostedPairedColumnData>[
          FrostedPairedColumnData(primary: 50, secondary: 100),
        ], maxAxisLabels: 12),
        0.5,
      );

      expect(frames[0].primary, 0.75);
      expect(frames[0].secondary, 0.5);
    });

    test('hands back the exact ends outside the transition', () {
      final PairedColumnFrames target = PairedColumnFrames.of(
        _six,
        maxAxisLabels: 12,
      );

      expect(
        PairedColumnFrames.lerp(
          PairedColumnFrames.of(_twelve, maxAxisLabels: 12),
          target,
          1,
        ),
        target,
      );
      expect(
        PairedColumnFrames.lerp(
          target,
          PairedColumnFrames.of(_twelve, maxAxisLabels: 12),
          0,
        ),
        target,
      );
    });
  });
}
