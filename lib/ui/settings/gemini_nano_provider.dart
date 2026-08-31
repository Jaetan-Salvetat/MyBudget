import 'dart:async';

import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/enums/quick_add_engine_mode.dart';
import 'package:mybudget/core/models/gemini_nano_download.dart';
import 'package:mybudget/core/providers/providers.dart';
import 'package:mybudget/ui/quick_add/quick_add_engine_provider.dart';
import 'package:mybudget/ui/settings/ai_settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gemini_nano_provider.g.dart';

@Riverpod(keepAlive: true)
class GeminiNanoDownloadNotifier extends _$GeminiNanoDownloadNotifier {
  StreamSubscription<GeminiNanoDownload>? _subscription;

  @override
  GeminiNanoDownload? build() {
    ref.onDispose(_stop);
    return null;
  }

  bool get isRunning =>
      state is GeminiNanoDownloadStarted || state is GeminiNanoDownloadProgress;

  void start() {
    if (isRunning) return;

    state = const GeminiNanoDownloadStarted(totalBytes: 0);
    _subscription = ref
        .read(geminiNanoServiceProvider)
        .download(
          ref.read(geminiNanoChannelProvider),
          GeminiNanoPreference.quickAdd,
        )
        .listen(_onStep, onDone: _stop);
  }

  void _onStep(GeminiNanoDownload step) {
    state = step;
    if (step is GeminiNanoDownloadCompleted) unawaited(_activate());
  }

  Future<void> _activate() async {
    ref.invalidate(geminiNanoStatusProvider);
    await ref
        .read(quickAddEngineModeProvider.notifier)
        .setMode(QuickAddEngineMode.geminiNano);
    ref.invalidate(quickAddEngineProvider);
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
