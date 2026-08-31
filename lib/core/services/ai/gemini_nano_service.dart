import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_status.dart';
import 'package:mybudget/core/models/gemini_nano_download.dart';

class GeminiNanoService {
  const GeminiNanoService({MethodChannel? channel, EventChannel? downloads})
    : _channel = channel ?? const MethodChannel(methodChannelName),
      _downloads = downloads ?? const EventChannel(downloadChannelName);

  static const String methodChannelName = 'fr.jaetan.mybudget/gemini_nano';
  static const String downloadChannelName =
      'fr.jaetan.mybudget/gemini_nano/download';

  static const String statusMethod = 'status';
  static const String warmUpMethod = 'warmUp';
  static const String generateMethod = 'generate';

  static const String promptArgument = 'prompt';
  static const String schemaArgument = 'schema';

  static const String eventKey = 'event';
  static const String totalBytesKey = 'totalBytes';
  static const String downloadedBytesKey = 'downloadedBytes';
  static const String codeKey = 'code';

  static const String startedEvent = 'started';
  static const String progressEvent = 'progress';
  static const String completedEvent = 'completed';
  static const String failedEvent = 'failed';

  final MethodChannel _channel;
  final EventChannel _downloads;

  bool get isSupportedPlatform =>
      defaultTargetPlatform == TargetPlatform.android;

  Future<GeminiNanoStatus> status() async {
    if (!isSupportedPlatform) return GeminiNanoStatus.unavailable;

    try {
      return GeminiNanoStatus.fromId(
        await _channel.invokeMethod<String>(statusMethod),
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Statut Gemini Nano illisible : $error\n$stackTrace');
      return GeminiNanoStatus.unavailable;
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('Canal Gemini Nano absent : $error\n$stackTrace');
      return GeminiNanoStatus.unavailable;
    }
  }

  Future<void> warmUp() async {
    if (!isSupportedPlatform) return;

    try {
      await _channel.invokeMethod<void>(warmUpMethod);
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Préchauffage Gemini Nano impossible : $error\n$stackTrace');
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('Canal Gemini Nano absent : $error\n$stackTrace');
    }
  }

  Future<String> generate({
    required String prompt,
    required String schema,
  }) async {
    if (!isSupportedPlatform) {
      throw const GeminiNanoException(GeminiNanoFailure.unavailable);
    }

    final String? raw;
    try {
      raw = await _channel.invokeMethod<String>(generateMethod, {
        promptArgument: prompt,
        schemaArgument: schema,
      });
    } on PlatformException catch (error) {
      throw GeminiNanoException(
        GeminiNanoFailure.fromPlatformCode(error.code),
        cause: error,
      );
    } on MissingPluginException catch (error) {
      throw GeminiNanoException(GeminiNanoFailure.unavailable, cause: error);
    }

    if (raw == null || raw.isEmpty) {
      throw const GeminiNanoException(GeminiNanoFailure.malformedResponse);
    }
    return raw;
  }

  Stream<GeminiNanoDownload> download() {
    if (!isSupportedPlatform) {
      return Stream<GeminiNanoDownload>.value(
        const GeminiNanoDownloadFailed(GeminiNanoFailure.unavailable),
      );
    }

    return _downloads.receiveBroadcastStream().transform(
      StreamTransformer<dynamic, GeminiNanoDownload>.fromHandlers(
        handleData: (event, sink) {
          final step = _stepFrom(event);
          if (step != null) sink.add(step);
        },
        handleError: (error, stackTrace, sink) {
          debugPrint(
            'Téléchargement Gemini Nano interrompu : $error\n$stackTrace',
          );
          sink.add(GeminiNanoDownloadFailed(_failureOf(error)));
        },
      ),
    );
  }

  GeminiNanoDownload? _stepFrom(Object? event) {
    if (event is! Map) return null;

    final total = _intOf(event[totalBytesKey]);
    return switch (event[eventKey]) {
      startedEvent => GeminiNanoDownloadStarted(totalBytes: total),
      progressEvent => GeminiNanoDownloadProgress(
        downloadedBytes: _intOf(event[downloadedBytesKey]),
        totalBytes: total,
      ),
      completedEvent => const GeminiNanoDownloadCompleted(),
      failedEvent => GeminiNanoDownloadFailed(
        GeminiNanoFailure.fromPlatformCode(event[codeKey] as String?),
      ),
      _ => null,
    };
  }

  static GeminiNanoFailure _failureOf(Object error) {
    if (error is PlatformException) {
      return GeminiNanoFailure.fromPlatformCode(error.code);
    }
    return GeminiNanoFailure.unknown;
  }

  static int _intOf(Object? value) => value is int ? value : 0;
}
