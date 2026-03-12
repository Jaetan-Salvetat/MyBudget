import 'package:flutter/foundation.dart';

class _ScenarioResult {
  final int number;
  final String description;
  final bool passed;

  _ScenarioResult({
    required this.number,
    required this.description,
    required this.passed,
  });
}

class TestReporter {
  TestReporter._();
  static final instance = TestReporter._();

  static final _scenarioRegex = RegExp(r'Scenario (\d+) - (.+)$');

  final List<_ScenarioResult> _results = [];
  int _total = 0;
  int _current = 0;

  void setTotal(int total) {
    _total = total;
    debugPrint('');
    debugPrint('🧪 Total: $_total tests');
    debugPrint('');
  }

  void registerFromTestName(String testName, bool passed) {
    final match = _scenarioRegex.firstMatch(testName);
    if (match == null) return;

    _current++;
    final number = int.parse(match.group(1)!);
    final description = match.group(2)!;
    final icon = passed ? '✅' : '❌';

    debugPrint('[$_current/$_total] $icon Scénario $number - $description');

    _results.add(_ScenarioResult(
      number: number,
      description: description,
      passed: passed,
    ));
  }

  void printSummary() {
    final total = _results.length;
    final failed = _results.where((r) => !r.passed).length;

    debugPrint('');
    if (failed == 0) {
      debugPrint('📊 Résultat: ✅ $total/$total test(s) passed');
    } else {
      debugPrint('📊 Résultat: ❌ $failed/$total test(s) failed');
    }
    debugPrint('');
  }
}
