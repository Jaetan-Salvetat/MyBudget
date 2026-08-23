import 'dart:io';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybudget/core/services/quick_add/quick_add_model_runner.dart';

class MockOnnxRuntime extends Mock implements OnnxRuntime {}

class MockOrtSession extends Mock implements OrtSession {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOnnxRuntime ort;
  late Directory tempDirectory;
  late QuickAddModelRunner runner;

  String cachedName(String version) => 'model_$version.onnx';

  File cachedFile(String name) => File('${tempDirectory.path}/$name');

  setUp(() async {
    ort = MockOnnxRuntime();
    tempDirectory = await Directory.systemTemp.createTemp('quick_add_runner');
    runner = QuickAddModelRunner(ort, tempDirectory: () async => tempDirectory);

    when(
      () => ort.createSessionFromAsset(any()),
    ).thenAnswer((_) async => MockOrtSession());
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  group('QuickAddModelRunner', () {
    test('loads the versioned asset', () async {
      await runner.load();

      expect(runner.isLoaded, isTrue);
      verify(
        () => ort.createSessionFromAsset(QuickAddModelRunner.assetPath),
      ).called(1);
    });

    test('deletes model extractions left by a previous version', () async {
      final stale = cachedFile('model.onnx')..writeAsStringSync('ancien');
      final olderVersion = cachedFile(cachedName('v1'))
        ..writeAsStringSync('ancien');

      await runner.load();

      expect(stale.existsSync(), isFalse);
      expect(olderVersion.existsSync(), isFalse);
    });

    test('keeps the extraction of the version in use', () async {
      final current = cachedFile(
        QuickAddModelRunner.assetPath.split('/').last,
      )..writeAsStringSync('courant');

      await runner.load();

      expect(current.existsSync(), isTrue);
    });

    test('leaves unrelated cached files untouched', () async {
      final unrelated = cachedFile('tokenizer.json')
        ..writeAsStringSync('tokenizer');

      await runner.load();

      expect(unrelated.existsSync(), isTrue);
    });

    test('loads even when the temporary directory is unreachable', () async {
      runner = QuickAddModelRunner(
        ort,
        tempDirectory: () async => throw const FileSystemException('no temp'),
      );

      await runner.load();

      expect(runner.isLoaded, isTrue);
    });

    test('does not recreate a session already loaded', () async {
      await runner.load();
      await runner.load();

      verify(() => ort.createSessionFromAsset(any())).called(1);
    });

    test('run before load fails explicitly', () {
      expect(
        () => runner.run((inputIds: [2, 1], attentionMask: [1, 1])),
        throwsStateError,
      );
    });
  });
}
