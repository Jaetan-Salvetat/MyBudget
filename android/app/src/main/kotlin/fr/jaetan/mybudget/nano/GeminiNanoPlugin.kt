package fr.jaetan.mybudget.nano

import android.util.Log
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.generateContentRequest
import com.google.mlkit.genai.prompt.generateTypedContentRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject

class GeminiNanoPlugin(messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val methods = MethodChannel(messenger, METHOD_CHANNEL).apply {
        setMethodCallHandler(this@GeminiNanoPlugin)
    }

    private val downloads = EventChannel(messenger, DOWNLOAD_CHANNEL).apply {
        setStreamHandler(this@GeminiNanoPlugin)
    }

    private var model: GenerativeModel? = null
    private var downloadJob: Job? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            STATUS_METHOD -> scope.launch { replyStatus(result) }
            WARM_UP_METHOD -> scope.launch { replyWarmUp(result) }
            GENERATE_METHOD -> scope.launch { replyGenerate(call, result) }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        downloadJob?.cancel()
        downloadJob = scope.launch { streamDownload(events) }
    }

    override fun onCancel(arguments: Any?) {
        downloadJob?.cancel()
        downloadJob = null
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
        downloads.setStreamHandler(null)
        scope.cancel()
        model?.close()
        model = null
    }

    private fun model(): GenerativeModel =
        model ?: Generation.getClient().also { model = it }

    private suspend fun replyStatus(result: MethodChannel.Result) {
        try {
            result.success(statusId(model().checkStatus()))
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            Log.w(TAG, "Statut Gemini Nano illisible", error)
            result.success(UNAVAILABLE_STATUS)
        }
    }

    private suspend fun replyWarmUp(result: MethodChannel.Result) {
        try {
            model().warmup()
            result.success(null)
        } catch (error: CancellationException) {
            throw error
        } catch (error: GenAiException) {
            result.error(error.errorCode.toString(), error.message, null)
        } catch (error: Exception) {
            result.error(UNKNOWN_CODE.toString(), error.message, null)
        }
    }

    private suspend fun replyGenerate(call: MethodCall, result: MethodChannel.Result) {
        val prompt = call.argument<String>(PROMPT_ARGUMENT)
        val schema = call.argument<String>(SCHEMA_ARGUMENT)

        if (prompt.isNullOrBlank() || schema != QUICK_ADD_SCHEMA) {
            result.error(
                NOT_SUPPORTED_CODE.toString(),
                "Schéma inconnu du canal natif : $schema",
                null,
            )
            return
        }

        try {
            val request = generateTypedContentRequest(
                generateContentRequest(TextPart(prompt)) { temperature = TEMPERATURE },
                QuickAddOutput::class,
            )
            val output = model().generateContent(request).candidates.firstOrNull()?.response
            if (output == null) {
                result.error(
                    STRUCTURED_OUTPUT_RESPONSE_ERROR_CODE.toString(),
                    "Gemini Nano n'a rendu aucun candidat exploitable",
                    null,
                )
                return
            }
            result.success(output.toJson())
        } catch (error: CancellationException) {
            throw error
        } catch (error: GenAiException) {
            result.error(error.errorCode.toString(), error.message, null)
        } catch (error: Exception) {
            result.error(UNKNOWN_CODE.toString(), error.message, null)
        }
    }

    private suspend fun streamDownload(events: EventChannel.EventSink) {
        var total = 0L
        try {
            model().download().collect { status ->
                when (status) {
                    is DownloadStatus.DownloadStarted -> {
                        total = status.bytesToDownload
                        events.success(
                            mapOf(EVENT_KEY to STARTED_EVENT, TOTAL_BYTES_KEY to total),
                        )
                    }

                    is DownloadStatus.DownloadProgress -> events.success(
                        mapOf(
                            EVENT_KEY to PROGRESS_EVENT,
                            TOTAL_BYTES_KEY to total,
                            DOWNLOADED_BYTES_KEY to status.totalBytesDownloaded,
                        ),
                    )

                    is DownloadStatus.DownloadCompleted -> events.success(
                        mapOf(EVENT_KEY to COMPLETED_EVENT),
                    )

                    is DownloadStatus.DownloadFailed ->
                        events.success(failedEvent(status.e.errorCode))
                }
            }
            events.endOfStream()
        } catch (error: CancellationException) {
            throw error
        } catch (error: GenAiException) {
            events.success(failedEvent(error.errorCode))
            events.endOfStream()
        } catch (error: Exception) {
            Log.w(TAG, "Téléchargement Gemini Nano interrompu", error)
            events.success(failedEvent(UNKNOWN_CODE))
            events.endOfStream()
        }
    }

    private fun failedEvent(code: Int): Map<String, Any?> = mapOf(
        EVENT_KEY to FAILED_EVENT,
        CODE_KEY to code.toString(),
    )

    private fun statusId(status: Int): String = when (status) {
        FeatureStatus.AVAILABLE -> AVAILABLE_STATUS
        FeatureStatus.DOWNLOADABLE -> DOWNLOADABLE_STATUS
        FeatureStatus.DOWNLOADING -> DOWNLOADING_STATUS
        else -> UNAVAILABLE_STATUS
    }

    private fun QuickAddOutput.toJson(): String = JSONObject()
        .put(CATEGORY_SLUG_KEY, categorySlug)
        .put(ALTERNATIVES_KEY, JSONArray(alternatives))
        .put(RECURRENCE_KEY, recurrence)
        .put(NAME_KEY, name)
        .toString()

    private companion object {
        const val TAG = "GeminiNano"

        const val METHOD_CHANNEL = "fr.jaetan.mybudget/gemini_nano"
        const val DOWNLOAD_CHANNEL = "fr.jaetan.mybudget/gemini_nano/download"

        const val STATUS_METHOD = "status"
        const val WARM_UP_METHOD = "warmUp"
        const val GENERATE_METHOD = "generate"

        const val PROMPT_ARGUMENT = "prompt"
        const val SCHEMA_ARGUMENT = "schema"

        const val QUICK_ADD_SCHEMA = "quick_add"

        const val AVAILABLE_STATUS = "available"
        const val DOWNLOADABLE_STATUS = "downloadable"
        const val DOWNLOADING_STATUS = "downloading"
        const val UNAVAILABLE_STATUS = "unavailable"

        const val EVENT_KEY = "event"
        const val TOTAL_BYTES_KEY = "totalBytes"
        const val DOWNLOADED_BYTES_KEY = "downloadedBytes"
        const val CODE_KEY = "code"

        const val STARTED_EVENT = "started"
        const val PROGRESS_EVENT = "progress"
        const val COMPLETED_EVENT = "completed"
        const val FAILED_EVENT = "failed"

        const val CATEGORY_SLUG_KEY = "category_slug"
        const val ALTERNATIVES_KEY = "alternatives"
        const val RECURRENCE_KEY = "recurrence"
        const val NAME_KEY = "name"

        const val UNKNOWN_CODE = 0
        const val NOT_SUPPORTED_CODE = 16
        const val STRUCTURED_OUTPUT_RESPONSE_ERROR_CODE = -105

        const val TEMPERATURE = 0.1f
    }
}
