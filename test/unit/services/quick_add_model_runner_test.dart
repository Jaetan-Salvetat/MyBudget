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

  const currentAsset = 'assets/models/model_v2.onnx';

  String cachedName(String version) => 'model_$version.onnx';

  File cachedFile(String name) => File('${tempDirectory.path}/$name');

  QuickAddModelRunner runnerWith({
    ModelAssetResolver? modelAsset,
    TempDirectoryResolver? tempDirectoryResolver,
  }) {
    return QuickAddModelRunner(
      ort,
      tempDirectory: tempDirectoryResolver ?? () async => tempDirectory,
      modelAsset: modelAsset ?? () async => currentAsset,
    );
  }

  setUp(() async {
    ort = MockOnnxRuntime();
    tempDirectory = await Directory.systemTemp.createTemp('quick_add_runner');
    runner = runnerWith();

    when(
      () => ort.createSessionFromAsset(any()),
    ).thenAnswer((_) async => MockOrtSession());
  });

  tearDown(() async {
    await tempDirectory.delete(recursive: true);
  });

  group('QuickAddModelRunner', () {
    test('loads the versioned asset found in the bundle', () async {
      await runner.load();

      expect(runner.isLoaded, isTrue);
      verify(() => ort.createSessionFromAsset(currentAsset)).called(1);
    });

    test('accepts any version the bundle carries', () async {
      runner = runnerWith(
        modelAsset: () async => 'assets/models/model_v7.onnx',
      );

      await runner.load();

      verify(
        () => ort.createSessionFromAsset('assets/models/model_v7.onnx'),
      ).called(1);
    });

    test('recognises a versioned model asset, and only that', () {
      expect(
        QuickAddModelRunner.assetPattern.hasMatch(
          'assets/models/model_v2.onnx',
        ),
        isTrue,
      );
      expect(
        QuickAddModelRunner.assetPattern.hasMatch('assets/models/model.onnx'),
        isFalse,
      );
      expect(
        QuickAddModelRunner.assetPattern.hasMatch(
          'assets/models/tokenizer.bin',
        ),
        isFalse,
      );
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
      final current = cachedFile(currentAsset.split('/').last)
        ..writeAsStringSync('courant');

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
      runner = runnerWith(
        tempDirectoryResolver: () async =>
            throw const FileSystemException('no temp'),
      );

      await runner.load();

      expect(runner.isLoaded, isTrue);
    });

    test('fails explicitly when the bundle carries no model', () async {
      runner = runnerWith(
        modelAsset: () async =>
            throw StateError('Aucun modele dans assets/models/'),
      );

      await expectLater(runner.load(), throwsStateError);
      expect(runner.isLoaded, isFalse);
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
