package fr.jaetan.mybudget.nano

import android.graphics.BitmapFactory
import android.os.SystemClock
import android.util.Log
import fr.jaetan.mybudget.BuildConfig
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.prompt.GenerateContentRequest
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.ModelPreference
import com.google.mlkit.genai.prompt.ModelReleaseStage
import com.google.mlkit.genai.prompt.generationConfig
import com.google.mlkit.genai.prompt.modelConfig
import com.google.mlkit.genai.prompt.ImagePart
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

        if (prompt.isNullOrBlank() || schema !in SCHEMAS) {
            result.error(
                NOT_SUPPORTED_CODE.toString(),
                "Schéma inconnu du canal natif : $schema",
                null,
            )
            return
        }

        val image = call.argument<ByteArray>(IMAGE_ARGUMENT)
        val photo = image?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
        if (image != null && photo == null) {
            result.error(
                NOT_SUPPORTED_CODE.toString(),
                "Image illisible par le canal natif",
                null,
            )
            return
        }

        val heat = call.argument<Double>(TEMPERATURE_ARGUMENT)?.toFloat() ?: TEMPERATURE
        val grain = call.argument<Int>(SEED_ARGUMENT)
        val inPrompt = call.argument<Boolean>(SCHEMA_IN_PROMPT_ARGUMENT) ?: false
        val thinking = call.argument<Boolean>(THINKING_ARGUMENT) ?: false
        val wanted = call.argument<Int>(CANDIDATES_ARGUMENT) ?: 1

        val content = if (photo == null) {
            generateContentRequest(TextPart(prompt)) {
                temperature = heat
                seed = grain
                enableThinking = thinking
                candidateCount = wanted
            }
        } else {
            generateContentRequest(ImagePart(photo), TextPart(prompt)) {
                temperature = heat
                seed = grain
                enableThinking = thinking
                candidateCount = wanted
            }
        }

        try {
            val startedAt = SystemClock.elapsedRealtime()
            val json = when (schema) {
                STORE_SCHEMA -> read(call, content, inPrompt, ReceiptStoreOutput::class) { it.toJson() }
                DATE_SCHEMA -> read(call, content, inPrompt, ReceiptDateOutput::class) { it.toJson() }
                TOTAL_SCHEMA -> read(call, content, inPrompt, ReceiptTotalOutput::class) { it.toJson() }
                else -> read(call, content, inPrompt, ReceiptItemsOutput::class) { it.toJson() }
            }
            val elapsed = SystemClock.elapsedRealtime() - startedAt

            if (json == null) {
                result.error(
                    STRUCTURED_OUTPUT_RESPONSE_ERROR_CODE.toString(),
                    "Gemini Nano a interrompu sa reponse",
                    null,
                )
                return
            }
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "Inference $schema ${elapsed}ms -> $json")
            }
            result.success(json)
        } catch (error: CancellationException) {
            throw error
        } catch (error: GenAiException) {
            Log.w(TAG, "Inference $schema refusee, code=${error.errorCode} : ${error.message}")
            result.error(error.errorCode.toString(), error.message, null)
        } catch (error: Exception) {
            result.error(UNKNOWN_CODE.toString(), error.message, null)
        }
    }

    private suspend fun <T : Any> read(
        call: MethodCall,
        content: GenerateContentRequest,
        includeSchemaInPrompt: Boolean,
        outputClass: kotlin.reflect.KClass<T>,
        toJson: (T) -> String,
    ): String? {
        val candidates = model(call.arguments)
            .generateContent(
                generateTypedContentRequest(content, outputClass, includeSchemaInPrompt),
            )
            .candidates

        val kept = candidates
            .filter { it.finishReason == FINISH_REASON_STOP }
            .mapNotNull { it.response?.let(toJson) }

        if (kept.isEmpty()) {
            Log.w(TAG, "Inference abandonnee, fins=${candidates.map { it.finishReason }}")
            return null
        }
        if (candidates.size == 1) return kept.first()

        return kept.joinToString(prefix = "[", postfix = "]")
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

    private fun ReceiptStoreOutput.toJson(): String = JSONObject()
        .put(STORE_KEY, store)
        .toString()

    private fun ReceiptDateOutput.toJson(): String = JSONObject()
        .put(DATE_KEY, date)
        .toString()

    private fun ReceiptTotalOutput.toJson(): String = JSONObject()
        .put(TOTAL_KEY, total)
        .toString()

    private fun ReceiptItemsOutput.toJson(): String = JSONObject()
        .put(TOTAL_KEY, total)
        .put(ITEMS_KEY, JSONArray(items.map(::itemJson)))
        .toString()

    private fun itemJson(item: ReceiptItemOutput): JSONObject = JSONObject()
        .put(NAME_KEY, item.name)
        .put(AMOUNT_KEY, item.amount)
        .put(DISCOUNT_KEY, item.discount)

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
        const val IMAGE_ARGUMENT = "image"
        const val TEMPERATURE_ARGUMENT = "temperature"
        const val SEED_ARGUMENT = "seed"
        const val SCHEMA_IN_PROMPT_ARGUMENT = "schemaInPrompt"
        const val THINKING_ARGUMENT = "thinking"
        const val CANDIDATES_ARGUMENT = "candidates"
        const val CHANNEL_ARGUMENT = "channel"
        const val PREFERENCE_ARGUMENT = "preference"

        const val PREVIEW_CHANNEL = "preview"
        const val FULL_PREFERENCE = "full"

        const val STORE_SCHEMA = "receiptStore"
        const val DATE_SCHEMA = "receiptDate"
        const val ITEMS_SCHEMA = "receiptItems"
        const val TOTAL_SCHEMA = "receiptTotal"

        val SCHEMAS = setOf(STORE_SCHEMA, DATE_SCHEMA, ITEMS_SCHEMA, TOTAL_SCHEMA)

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

        const val STORE_KEY = "store"
        const val DATE_KEY = "date"
        const val TOTAL_KEY = "total"
        const val ITEMS_KEY = "items"
        const val NAME_KEY = "name"
        const val AMOUNT_KEY = "amount"
        const val DISCOUNT_KEY = "discount"

        const val FINISH_REASON_STOP = 0

        const val UNKNOWN_CODE = 0
        const val NOT_SUPPORTED_CODE = 16
        const val STRUCTURED_OUTPUT_RESPONSE_ERROR_CODE = -105

        const val TEMPERATURE = 0.1f
    }
}
