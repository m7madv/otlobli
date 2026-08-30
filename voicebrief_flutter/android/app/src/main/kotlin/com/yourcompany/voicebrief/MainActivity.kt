package app.voicebrief.mobile

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.OpenableColumns
import android.provider.AlarmClock
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.Calendar

@UnstableApi
class MainActivity : FlutterActivity() {
    private val channelName = "voicebrief/share"
    private var channel: MethodChannel? = null
    private var calendarChannel: MethodChannel? = null
    private var reminderChannel: MethodChannel? = null
    private var microphoneChannel: MethodChannel? = null
    private var audioEditChannel: MethodChannel? = null
    private var microphonePermissionResult: MethodChannel.Result? = null
    private var pendingShare: Map<String, Any>? = null
    private var pendingShareError = false
    private var lastFingerprint: String? = null
    private var lastFingerprintAt = 0L
    private var dartReady = false
    private var activeAudioTransformer: Transformer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                if (call.method == "takePendingShare") {
                    dartReady = true
                    val value = pendingShare
                    pendingShare = null
                    val hadError = pendingShareError
                    pendingShareError = false
                    result.success(value ?: if (hadError) mapOf("error" to "shareHandoff") else null)
                } else {
                    result.notImplemented()
                }
            }
        }
        calendarChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "voicebrief/calendar",
        ).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                if (call.method != "openEvent") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val title = call.argument<String>("title") ?: "VoiceBrief event"
                val description = call.argument<String>("description") ?: ""
                val startMillis = call.argument<Number>("startMillis")?.toLong()
                val endMillis = call.argument<Number>("endMillis")?.toLong()
                if (startMillis == null || endMillis == null || endMillis <= startMillis) {
                    result.error("invalid_event", "Invalid calendar event range", null)
                    return@setMethodCallHandler
                }
                runCatching {
                    startActivity(
                        Intent(Intent.ACTION_INSERT)
                            .setData(CalendarContract.Events.CONTENT_URI)
                            .putExtra(CalendarContract.Events.TITLE, title)
                            .putExtra(CalendarContract.Events.DESCRIPTION, description)
                            .putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, startMillis)
                            .putExtra(CalendarContract.EXTRA_EVENT_END_TIME, endMillis),
                    )
                }.onSuccess { result.success(true) }
                    .onFailure { result.error("calendar_unavailable", "No calendar editor is available", null) }
            }
        }
        reminderChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "voicebrief/reminders",
        ).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                if (call.method != "schedule") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val fireMillis = call.argument<Number>("fireMillis")?.toLong()
                if (fireMillis == null || fireMillis <= System.currentTimeMillis()) {
                    result.error("invalid_reminder", "Reminder must be in the future", null)
                    return@setMethodCallHandler
                }
                val fireTime = Calendar.getInstance().apply { timeInMillis = fireMillis }
                val title = call.argument<String>("title") ?: "VoiceBrief"
                runCatching {
                    startActivity(
                        Intent(AlarmClock.ACTION_SET_ALARM)
                            .putExtra(AlarmClock.EXTRA_HOUR, fireTime.get(Calendar.HOUR_OF_DAY))
                            .putExtra(AlarmClock.EXTRA_MINUTES, fireTime.get(Calendar.MINUTE))
                            .putExtra(AlarmClock.EXTRA_MESSAGE, title)
                            .putExtra(AlarmClock.EXTRA_SKIP_UI, true),
                    )
                }.onSuccess { result.success(true) }
                    .onFailure { result.error("reminder_unavailable", "No alarm app is available", null) }
            }
        }
        microphoneChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "voicebrief/microphone",
        ).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                if (call.method != "requestPermission") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (
                    ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
                    PackageManager.PERMISSION_GRANTED
                ) {
                    result.success(true)
                    return@setMethodCallHandler
                }
                if (microphonePermissionResult != null) {
                    result.error("request_in_progress", "A microphone permission request is already active", null)
                    return@setMethodCallHandler
                }
                microphonePermissionResult = result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.RECORD_AUDIO),
                    MICROPHONE_PERMISSION_REQUEST_CODE,
                )
            }
        }
        audioEditChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "voicebrief/audio_edit",
        ).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                if (call.method != "trim") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                trimAudio(call.arguments, result)
            }
        }
        receiveShareIntent(intent)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != MICROPHONE_PERMISSION_REQUEST_CODE) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        microphonePermissionResult?.success(granted)
        microphonePermissionResult = null
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        receiveShareIntent(intent)
    }

    private fun receiveShareIntent(incoming: Intent?) {
        if (incoming?.action != Intent.ACTION_SEND) return
        val mime = incoming.type?.substringBefore(';')?.lowercase() ?: return
        if (!isSupportedAudioMime(mime)) return
        val uri = incoming.sharedUri() ?: return
        val fingerprint = sha256("${uri}|${incoming.clipData?.description}|$mime")
        val now = System.currentTimeMillis()
        if (fingerprint == lastFingerprint && now - lastFingerprintAt < DUPLICATE_WINDOW_MILLIS) return

        var copiedFile: File? = null
        runCatching {
            val displayName = normalizedAudioName(queryDisplayName(uri), mime)
            val extension = displayName.substringAfterLast('.')
            val target = File(cacheDir, "voicebrief_share_${System.currentTimeMillis()}.$extension")
            copiedFile = target
            contentResolver.openInputStream(uri).use { input ->
                requireNotNull(input) { "Unreadable shared audio" }
                FileOutputStream(target).use { output ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    var total = 0L
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        total += read
                        require(total <= MAX_AUDIO_BYTES) { "Shared audio is too large" }
                        output.write(buffer, 0, read)
                    }
                }
            }
            mapOf(
                "path" to target.absolutePath,
                "name" to displayName,
                "mime" to mime,
                "source" to "androidShare",
                "sizeBytes" to target.length(),
                "durationSeconds" to readDurationSeconds(target),
            )
        }.onSuccess { payload ->
            lastFingerprint = fingerprint
            lastFingerprintAt = now
            pendingShare = payload
            if (dartReady) {
                pendingShare = null
                channel?.invokeMethod("shareReceived", payload)
            }
        }.onFailure {
            copiedFile?.delete()
            pendingShareError = true
            if (dartReady) {
                pendingShareError = false
                channel?.invokeMethod("shareError", null)
            }
            // No URI, filename, or platform exception is logged.
        }
    }

    @Suppress("DEPRECATION")
    private fun Intent.sharedUri(): Uri? =
        if (android.os.Build.VERSION.SDK_INT >= 33) {
            getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme != "content") return uri.lastPathSegment
        var cursor: Cursor? = null
        return try {
            cursor = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            if (cursor?.moveToFirst() == true) cursor.getString(0) else null
        } finally {
            cursor?.close()
        }
    }

    private fun isSupportedAudioMime(mime: String): Boolean =
        mime.startsWith("audio/") || mime == "application/ogg"

    private fun readDurationSeconds(file: File): Int {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(file.absolutePath)
            val millis = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull()
                ?: 0L
            ((millis + 999L) / 1000L).toInt()
        } catch (_: RuntimeException) {
            0
        } finally {
            retriever.release()
        }
    }

    private fun trimAudio(arguments: Any?, result: MethodChannel.Result) {
        if (activeAudioTransformer != null) {
            result.error("audio_edit_busy", "An audio edit is already running", null)
            return
        }
        val values = arguments as? Map<*, *>
        val inputPath = values?.get("inputPath") as? String
        val outputPath = values?.get("outputPath") as? String
        val startMs = (values?.get("startMs") as? Number)?.toLong()
        val endMs = (values?.get("endMs") as? Number)?.toLong()
        if (inputPath == null || outputPath == null || startMs == null || endMs == null ||
            startMs < 0L || endMs - startMs < 1_000L
        ) {
            result.error("invalid_audio_edit", "Invalid audio edit range", null)
            return
        }
        val input = File(inputPath).canonicalFile
        val output = File(outputPath).canonicalFile
        val cacheRoot = cacheDir.canonicalFile
        val cachePrefix = cacheRoot.absolutePath + File.separator
        if (!input.isFile || !input.absolutePath.startsWith(cachePrefix) ||
            !output.absolutePath.startsWith(cachePrefix)
        ) {
            result.error("invalid_audio_edit", "Audio edit paths are outside private storage", null)
            return
        }
        output.delete()
        val mediaItem = MediaItem.Builder()
            .setUri(Uri.fromFile(input))
            .setClippingConfiguration(
                MediaItem.ClippingConfiguration.Builder()
                    .setStartPositionMs(startMs)
                    .setEndPositionMs(endMs)
                    .build(),
            )
            .build()
        val editedMediaItem = EditedMediaItem.Builder(mediaItem)
            .setRemoveVideo(true)
            .build()
        val listener = object : Transformer.Listener {
            override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                activeAudioTransformer = null
                if (output.isFile && output.length() > 0L) {
                    result.success(true)
                } else {
                    result.error("audio_edit_failed", "Trimmed audio was not created", null)
                }
            }

            override fun onError(
                composition: Composition,
                exportResult: ExportResult,
                exportException: ExportException,
            ) {
                activeAudioTransformer = null
                output.delete()
                result.error("audio_edit_failed", "Audio trim failed", null)
            }
        }
        runCatching {
            Transformer.Builder(this)
                .setAudioMimeType(MimeTypes.AUDIO_AAC)
                .addListener(listener)
                .build()
                .also { transformer ->
                    activeAudioTransformer = transformer
                    transformer.start(editedMediaItem, output.absolutePath)
                }
        }.onFailure {
            activeAudioTransformer = null
            output.delete()
            result.error("audio_edit_failed", "Audio trim could not start", null)
        }
    }

    override fun onDestroy() {
        activeAudioTransformer?.cancel()
        activeAudioTransformer = null
        super.onDestroy()
    }

    private fun normalizedAudioName(rawName: String?, mime: String): String {
        val safeName = rawName
            ?.substringAfterLast('/')
            ?.substringAfterLast('\\')
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: "shared-audio"
        val currentExtension = safeName.substringAfterLast('.', "").lowercase()
        val canonicalExtension = when {
            currentExtension == "opus" -> "ogg"
            currentExtension in SUPPORTED_EXTENSIONS -> currentExtension
            mime in setOf("audio/ogg", "audio/opus", "audio/x-opus+ogg", "application/ogg") -> "ogg"
            mime in setOf("audio/mp4", "audio/x-m4a") -> "m4a"
            mime in setOf("audio/mpeg", "audio/mp3") -> "mp3"
            mime in setOf("audio/wav", "audio/x-wav") -> "wav"
            mime == "audio/flac" -> "flac"
            mime == "audio/webm" -> "webm"
            else -> throw IllegalArgumentException("Unsupported shared audio format")
        }
        val stem = if (currentExtension.isEmpty()) safeName else safeName.substringBeforeLast('.')
        return "${stem.ifBlank { "shared-audio" }}.$canonicalExtension"
    }

    private fun sha256(value: String): String = MessageDigest
        .getInstance("SHA-256")
        .digest(value.toByteArray())
        .joinToString("") { "%02x".format(it) }

    companion object {
        private val SUPPORTED_EXTENSIONS = setOf(
            "flac",
            "mp3",
            "mp4",
            "mpeg",
            "mpga",
            "m4a",
            "ogg",
            "wav",
            "webm",
        )
        private const val MAX_AUDIO_BYTES = 25L * 1024L * 1024L
        private const val DUPLICATE_WINDOW_MILLIS = 10_000L
        private const val MICROPHONE_PERMISSION_REQUEST_CODE = 4102
    }
}
