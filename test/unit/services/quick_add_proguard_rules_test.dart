import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ONNX Runtime resout ses classes Java depuis le JNI, par leur nom complet :
/// R8 ne voit aucune reference et les renomme. La session se charge quand meme,
/// puis `OrtSession.run` abandonne le processus sur `GetMethodID` — un crash
/// natif invisible en debug, ou le shrinking est desactive.
void main() {
  group('proguard-rules.pro', () {
    final rules = File('android/app/proguard-rules.pro').readAsStringSync();

    test('garde les classes ONNX Runtime resolues par JNI', () {
      expect(rules, contains('-keep class ai.onnxruntime.** { *; }'));
    });

    test('tait les avertissements ONNX Runtime', () {
      expect(rules, contains('-dontwarn ai.onnxruntime.**'));
    });
  });
}
