import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

  group('proguard-rules.pro — Gemini Nano', () {
    final rules = File('android/app/proguard-rules.pro').readAsStringSync();

    test('garde le schéma généré, résolu par réflexion par ML Kit', () {
      expect(rules, contains('-keep class fr.jaetan.mybudget.nano.** { *; }'));
    });

    test('garde les classes ML Kit GenAI', () {
      expect(rules, contains('-keep class com.google.mlkit.genai.** { *; }'));
    });
  });
}
