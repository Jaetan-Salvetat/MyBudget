import 'dart:async';

import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/models/gemini_nano_download.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/core/services/preferences_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gemini_nano_provider.g.dart';

@Riverpod(keepAlive: true)
class GeminiNanoScanNotifier extends _$GeminiNanoScanNotifier {
  @override
  bool build() => PreferencesService.isGeminiNanoScanEnabled();

  Future<void> setEnabled(bool enabled) async {
    if (enabled == state) return;

    await PreferencesService.setGeminiNanoScanEnabled(enabled);
    state = enabled;
  }
}

@Riverpod(keepAlive: true)
class GeminiNanoDownloadNotifier extends _$GeminiNanoDownloadNotifier {
  StreamSubscription<GeminiNanoDownload>? _subscription;

  @override
  GeminiNanoDownload? build() {
    ref.onDispose(_stop);
    return null;
  }

  bool get _isRunning =>
      state is GeminiNanoDownloadStarted || state is GeminiNanoDownloadProgress;

  void start() {
    if (_isRunning) return;

    state = const GeminiNanoDownloadStarted(totalBytes: 0);
    _subscription = ref
        .read(geminiNanoServiceProvider)
        .download(GeminiNanoChannel.fallback, GeminiNanoPreference.scan)
        .listen(_onStep, onDone: _stop);
  }

  void _onStep(GeminiNanoDownload step) {
    state = step;
    if (step is GeminiNanoDownloadCompleted) unawaited(_activate());
  }

  Future<void> _activate() async {
    ref.invalidate(geminiNanoStatusProvider);
    await ref.read(geminiNanoScanProvider.notifier).setEnabled(true);
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
