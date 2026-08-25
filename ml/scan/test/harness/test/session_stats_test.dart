import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_harness/local_flow.dart';
import 'package:ocr_harness/session_stats.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

LocalScanResult resultWith(
  FlowStage stage, {
  bool retry = false,
  int ms = 100,
}) {
  final receipt = ExtractedReceipt(
    store: null,
    date: null,
    total: 1.0,
    subtotal: null,
    payment: null,
    items: [ExtractedItem(name: 'A', amount: 1.0, discount: 0.0)],
  );
  OcrPass pass(int latency) => OcrPass(
    recognized: RecognizedText(text: '', blocks: const []),
    lines: const [],
    receipt: receipt,
    latencyMs: latency,
    imageWidth: 1,
    imageHeight: 1,
  );
  return LocalScanResult(
    outcome: FlowOutcome(stage: stage, items: receipt.items, total: 1.0),
    pass1: pass(ms),
    retry: retry ? pass(ms) : null,
  );
}

void main() {
  test('counts stages, verified rate, retries and latencies', () {
    final stats = SessionStats();
    stats.record(resultWith(FlowStage.local, ms: 100));
    stats.record(resultWith(FlowStage.localDp, retry: true, ms: 200));
    stats.record(resultWith(FlowStage.confirm, retry: true, ms: 300));
    stats.recordFailure();

    expect(stats.total, 3);
    expect(stats.verified, 2);
    expect(stats.verifiedRate, closeTo(2 / 3, 1e-9));
    expect(stats.retries, 2);
    expect(stats.failures, 1);
    expect(stats.medianLatencyMs, 400);
    expect(stats.byStage[FlowStage.localDp], 1);
  });

  test('reset clears everything and notifies', () {
    final stats = SessionStats();
    var notified = 0;
    stats.addListener(() => notified++);
    stats.record(resultWith(FlowStage.local));
    stats.reset();
    expect(stats.total, 0);
    expect(stats.medianLatencyMs, isNull);
    expect(notified, 2);
  });
}
