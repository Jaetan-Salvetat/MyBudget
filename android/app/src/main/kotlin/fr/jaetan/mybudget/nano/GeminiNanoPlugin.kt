package fr.jaetan.mybudget.nano

import android.os.SystemClock
import android.util.Log
import fr.jaetan.mybudget.BuildConfig
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.ModelPreference
import com.google.mlkit.genai.prompt.ModelReleaseStage
import com.google.mlkit.genai.prompt.generationConfig
import com.google.mlkit.genai.prompt.modelConfig
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

    private val models = mutableMapOf<String, GenerativeModel>()
    private var downloadJob: Job? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            STATUS_METHOD -> scope.launch { replyStatus(call, result) }
            MODEL_NAME_METHOD -> scope.launch { replyModelName(call, result) }
            WARM_UP_METHOD -> scope.launch { replyWarmUp(call, result) }
            GENERATE_METHOD -> scope.launch { replyGenerate(call, result) }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        downloadJob?.cancel()
        downloadJob = scope.launch { streamDownload(arguments, events) }
    }

    override fun onCancel(arguments: Any?) {
        downloadJob?.cancel()
        downloadJob = null
    }

    fun dispose() {
        methods.setMethodCallHandler(null)
        downloads.setStreamHandler(null)
        scope.cancel()
        models.values.forEach(GenerativeModel::close)
        models.clear()
    }

    private fun model(arguments: Any?): GenerativeModel {
        val channel = idOf(arguments, CHANNEL_ARGUMENT)
        val preference = idOf(arguments, PREFERENCE_ARGUMENT)

        return models.getOrPut("$channel/$preference") {
            Generation.getClient(
                generationConfig {
                    modelConfig = modelConfig {
                        this.preference = preferenceOf(preference)
                        this.releaseStage = releaseStageOf(channel)
                    }
                },
            )
        }
    }

    private fun idOf(arguments: Any?, key: String): String? =
        (arguments as? Map<*, *>)?.get(key) as? String

    private fun preferenceOf(id: String?): Int =
        if (id == FULL_PREFERENCE) ModelPreference.FULL else ModelPreference.FAST

    private fun releaseStageOf(id: String?): Int =
        if (id == PREVIEW_CHANNEL) ModelReleaseStage.PREVIEW else ModelReleaseStage.STABLE

    private suspend fun replyStatus(call: MethodCall, result: MethodChannel.Result) {
        try {
            val model = model(call.arguments)
            val status = model.checkStatus()
            if (status == FeatureStatus.AVAILABLE &&
                !model.isStructuredOutputFeatureAvailable()
            ) {
                Log.w(TAG, "Gemini Nano est là mais sans sortie structurée")
                result.success(UNAVAILABLE_STATUS)
                return
            }
            result.success(statusId(status))
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            Log.w(TAG, "Statut Gemini Nano illisible", error)
            result.success(UNAVAILABLE_STATUS)
        }
    }

    private suspend fun replyModelName(call: MethodCall, result: MethodChannel.Result) {
        try {
            result.success(model(call.arguments).getBaseModelName())
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            Log.w(TAG, "Nom du modèle Gemini Nano illisible", error)
            result.success(null)
        }
    }

    private suspend fun replyWarmUp(call: MethodCall, result: MethodChannel.Result) {
        try {
            model(call.arguments).warmup()
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
            val startedAt = SystemClock.elapsedRealtime()
            val candidate = model(call.arguments)
                .generateContent(request)
                .candidates
                .firstOrNull()
            val elapsed = SystemClock.elapsedRealtime() - startedAt

            val output = candidate?.response
            val finishReason = candidate?.finishReason
            if (output == null || finishReason != FINISH_REASON_STOP) {
                Log.w(TAG, "Inference abandonnee en ${elapsed}ms, fin=$finishReason")
                result.error(
                    STRUCTURED_OUTPUT_RESPONSE_ERROR_CODE.toString(),
                    "Gemini Nano a interrompu sa reponse (fin=$finishReason)",
                    null,
                )
                return
            }

            val json = output.toJson()
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "Inference ${elapsed}ms -> $json")
            }
            result.success(json)
        } catch (error: CancellationException) {
            throw error
        } catch (error: GenAiException) {
            result.error(error.errorCode.toString(), error.message, null)
        } catch (error: Exception) {
            result.error(UNKNOWN_CODE.toString(), error.message, null)
        }
    }

    private suspend fun streamDownload(arguments: Any?, events: EventChannel.EventSink) {
        var total = 0L
        try {
            model(arguments).download().collect { status ->
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
        const val MODEL_NAME_METHOD = "modelName"
        const val WARM_UP_METHOD = "warmUp"
        const val GENERATE_METHOD = "generate"

        const val PROMPT_ARGUMENT = "prompt"
        const val SCHEMA_ARGUMENT = "schema"
        const val CHANNEL_ARGUMENT = "channel"
        const val PREFERENCE_ARGUMENT = "preference"

        const val PREVIEW_CHANNEL = "preview"
        const val FULL_PREFERENCE = "full"

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

        const val FINISH_REASON_STOP = 0

        const val UNKNOWN_CODE = 0
        const val NOT_SUPPORTED_CODE = 16
        const val STRUCTURED_OUTPUT_RESPONSE_ERROR_CODE = -105

        const val TEMPERATURE = 0.1f
    }
}
