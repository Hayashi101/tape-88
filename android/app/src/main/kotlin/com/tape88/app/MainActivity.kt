package com.tape88.app

import android.Manifest
import android.content.ContentUris
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.media.AudioManager
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {
    private companion object {
        const val MIN_TRACK_DURATION_MS = 30_000
        const val MIN_TRACK_SIZE_BYTES = 300 * 1024
    }

    private val channelName = "tape_88/media_library"
    private val volumeChannelName = "tape_88/device_volume"
    private val volumeEventsName = "tape_88/device_volume_changes"
    private val homeWidgetChannelName = "tape_88/home_widget"
    private val permissionRequestCode = 8801
    private var permissionResult: MethodChannel.Result? = null
    private val artworkExecutor = Executors.newSingleThreadExecutor()
    private val audioManager by lazy {
        getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }
    private var volumeReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasAudioPermission())
                    "requestPermission" -> requestAudioPermission(result)
                    "queryTracks" -> {
                        if (!hasAudioPermission()) {
                            result.error("permission_denied", "Audio permission is required", null)
                        } else {
                            artworkExecutor.execute {
                                try {
                                    val tracks = queryTracks()
                                    runOnUiThread { result.success(tracks) }
                                } catch (error: Exception) {
                                    runOnUiThread {
                                        result.error(
                                            "media_query_failed",
                                            error.message ?: "Unable to scan the music library",
                                            null,
                                        )
                                    }
                                }
                            }
                        }
                    }
                    "loadArtwork" -> {
                        val source = call.argument<String>("source")
                        val trackId = call.argument<String>("trackId")
                        if (source == null || trackId == null) {
                            result.success(null)
                        } else {
                            artworkExecutor.execute {
                                val bytes = loadArtworkThumbnail(source, trackId)
                                runOnUiThread { result.success(bytes) }
                            }
                        }
                    }
                    "cacheArtwork" -> {
                        val source = call.argument<String>("source")
                        val trackId = call.argument<String>("trackId")
                        result.success(
                            if (source != null && trackId != null) {
                                cacheArtwork(source, trackId)
                            } else {
                                null
                            },
                        )
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, volumeChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMediaVolume" -> result.success(mediaVolume())
                    "setMediaVolume" -> {
                        val volume = call.argument<Double>("volume")
                        if (volume == null) {
                            result.error("invalid_volume", "Volume is required", null)
                        } else {
                            setMediaVolume(volume)
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, homeWidgetChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updatePlayback" -> {
                        Tape88WidgetProvider.updatePlayback(
                            applicationContext,
                            call.argument<String>("title"),
                            call.argument<String>("artist"),
                            call.argument<Boolean>("hasTrack") ?: false,
                            call.argument<Boolean>("isPlaying") ?: false,
                            call.argument<Number>("positionMs")?.toLong() ?: 0L,
                            call.argument<Number>("durationMs")?.toLong() ?: 0L,
                            call.argument<ByteArray>("artwork"),
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, volumeEventsName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    volumeReceiver?.let(::unregisterReceiver)
                    volumeReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            events.success(mediaVolume())
                        }
                    }
                    val filter = IntentFilter("android.media.VOLUME_CHANGED_ACTION")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(volumeReceiver, filter, RECEIVER_NOT_EXPORTED)
                    } else {
                        @Suppress("DEPRECATION")
                        registerReceiver(volumeReceiver, filter)
                    }
                    events.success(mediaVolume())
                }

                override fun onCancel(arguments: Any?) {
                    volumeReceiver?.let(::unregisterReceiver)
                    volumeReceiver = null
                }
            })
    }

    private fun mediaVolume(): Double {
        val maximum = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        if (maximum <= 0) return 0.0
        return audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / maximum
    }

    private fun setMediaVolume(volume: Double) {
        val maximum = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val level = (volume.coerceIn(0.0, 1.0) * maximum).toInt()
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, level, 0)
    }

    private fun audioPermission(): String =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }

    private fun hasAudioPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, audioPermission()) == PackageManager.PERMISSION_GRANTED

    private fun requestAudioPermission(result: MethodChannel.Result) {
        if (hasAudioPermission()) {
            result.success(true)
            return
        }
        if (permissionResult != null) {
            result.error("request_in_progress", "A permission request is already active", null)
            return
        }
        permissionResult = result
        requestPermissions(arrayOf(audioPermission()), permissionRequestCode)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permissionRequestCode) {
            permissionResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
            permissionResult = null
        }
    }

    private fun queryTracks(): List<Map<String, Any?>> {
        val tracks = mutableListOf<Map<String, Any?>>()
        val projection = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.TRACK,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            projection += MediaStore.Audio.Media.BITRATE
        }
        val selectionParts = mutableListOf(
            "${MediaStore.Audio.Media.IS_MUSIC} != 0",
            "${MediaStore.Audio.Media.IS_RINGTONE} = 0",
            "${MediaStore.Audio.Media.IS_ALARM} = 0",
            "${MediaStore.Audio.Media.IS_NOTIFICATION} = 0",
            "${MediaStore.Audio.Media.IS_PODCAST} = 0",
            "${MediaStore.Audio.Media.DURATION} >= ?",
            "${MediaStore.Audio.Media.SIZE} >= ?",
        )
        val selectionArgs = mutableListOf(
            MIN_TRACK_DURATION_MS.toString(),
            MIN_TRACK_SIZE_BYTES.toString(),
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            selectionParts += "${MediaStore.Audio.Media.IS_AUDIOBOOK} = 0"
            selectionParts += "${MediaStore.Audio.Media.IS_PENDING} = 0"
            selectionParts += "(LOWER(${MediaStore.Audio.Media.RELATIVE_PATH}) LIKE ? OR LOWER(${MediaStore.Audio.Media.RELATIVE_PATH}) LIKE ?)"
            selectionArgs += "music/%"
            selectionArgs += "download/music/%"
        } else {
            @Suppress("DEPRECATION")
            val dataColumn = MediaStore.Audio.Media.DATA
            selectionParts += "LOWER($dataColumn) LIKE ?"
            selectionArgs += "%/music/%"
        }

        // Some recorders incorrectly mark their output as music. Path filtering above
        // handles most cases; these exclusions cover recorder folders nested in Music.
        val pathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.RELATIVE_PATH
        } else {
            @Suppress("DEPRECATION")
            MediaStore.Audio.Media.DATA
        }
        listOf("recording", "recorder", "voice", "ringtones", "alarms", "notifications")
            .forEach { folder ->
                selectionParts += "LOWER($pathColumn) NOT LIKE ?"
                selectionArgs += "%/$folder/%"
            }

        contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection.toTypedArray(),
            selectionParts.joinToString(" AND "),
            selectionArgs.toTypedArray(),
            "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC",
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val albumIdColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val mimeTypeColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)
            val trackNumberColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
            val bitrateColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                cursor.getColumnIndex(MediaStore.Audio.Media.BITRATE)
            } else {
                -1
            }
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                val albumId = cursor.getLong(albumIdColumn)
                tracks.add(
                    mapOf(
                        "id" to id.toString(),
                        "title" to cursor.getString(titleColumn),
                        "artist" to cursor.getString(artistColumn),
                        "album" to cursor.getString(albumColumn),
                        "durationMs" to cursor.getLong(durationColumn),
                        "mimeType" to cursor.getString(mimeTypeColumn),
                        "trackNumber" to cursor.getInt(trackNumberColumn),
                        "bitrate" to if (bitrateColumn >= 0) cursor.getInt(bitrateColumn) else null,
                        "artworkUri" to if (albumId > 0) {
                            "content://media/external/audio/albumart/$albumId"
                        } else {
                            null
                        },
                        "source" to ContentUris.withAppendedId(
                            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                            id,
                        ).toString(),
                    ),
                )
            }
        }
        return tracks
    }

    private fun loadEmbeddedArtwork(source: String): ByteArray? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(this, Uri.parse(source))
            retriever.embeddedPicture
        } catch (_: Exception) {
            null
        } finally {
            retriever.release()
        }
    }

    private fun cacheArtwork(source: String, trackId: String): String? {
        val safeId = trackId.replace(Regex("[^A-Za-z0-9_-]"), "_")
        val directory = File(cacheDir, "media_artwork").apply { mkdirs() }
        val target = File(directory, "$safeId.jpg")
        if (target.exists() && target.length() > 0) return target.absolutePath
        val bytes = loadEmbeddedArtwork(source) ?: return null
        return try {
            target.writeBytes(bytes)
            target.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun loadArtworkThumbnail(source: String, trackId: String): ByteArray? {
        val safeId = trackId.replace(Regex("[^A-Za-z0-9_-]"), "_")
        val directory = File(cacheDir, "artwork_thumbnails").apply { mkdirs() }
        val target = File(directory, "$safeId.jpg")
        if (target.exists() && target.length() > 0) return target.readBytes()
        val original = loadEmbeddedArtwork(source) ?: return null
        val bitmap = BitmapFactory.decodeByteArray(original, 0, original.size) ?: return null
        val side = 128
        val scale = minOf(side.toFloat() / bitmap.width, side.toFloat() / bitmap.height, 1f)
        val width = maxOf(1, (bitmap.width * scale).toInt())
        val height = maxOf(1, (bitmap.height * scale).toInt())
        val thumbnail = if (width == bitmap.width && height == bitmap.height) {
            bitmap
        } else {
            Bitmap.createScaledBitmap(bitmap, width, height, true)
        }
        return try {
            ByteArrayOutputStream().use { output ->
                thumbnail.compress(Bitmap.CompressFormat.JPEG, 82, output)
                output.toByteArray().also { target.writeBytes(it) }
            }
        } catch (_: Exception) {
            null
        } finally {
            if (thumbnail !== bitmap) thumbnail.recycle()
            bitmap.recycle()
        }
    }
}
