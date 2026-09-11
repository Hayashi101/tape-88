package com.tape88.app

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.KeyEvent
import android.widget.RemoteViews
import kotlin.math.roundToInt

class Tape88WidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id -> updateWidget(context, appWidgetManager, id) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val keyCode = when (intent.action) {
            ACTION_PREVIOUS -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            ACTION_PLAY_PAUSE -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            ACTION_NEXT -> KeyEvent.KEYCODE_MEDIA_NEXT
            else -> return
        }
        if (intent.action == ACTION_PLAY_PAUSE) {
            val preferences = preferences(context)
            preferences.edit()
                .putBoolean(KEY_IS_PLAYING, !preferences.getBoolean(KEY_IS_PLAYING, false))
                .apply()
            updateAll(context)
        }
        sendMediaKey(context, keyCode)
    }

    companion object {
        private const val PREFERENCES = "tape_88_widget"
        private const val KEY_TITLE = "title"
        private const val KEY_ARTIST = "artist"
        private const val KEY_HAS_TRACK = "hasTrack"
        private const val KEY_IS_PLAYING = "isPlaying"
        private const val KEY_POSITION_MS = "positionMs"
        private const val KEY_DURATION_MS = "durationMs"
        private const val KEY_ARTWORK_PATH = "artworkPath"

        private const val ACTION_PREVIOUS = "com.tape88.app.widget.PREVIOUS"
        private const val ACTION_PLAY_PAUSE = "com.tape88.app.widget.PLAY_PAUSE"
        private const val ACTION_NEXT = "com.tape88.app.widget.NEXT"

        fun updatePlayback(
            context: Context,
            title: String?,
            artist: String?,
            hasTrack: Boolean,
            isPlaying: Boolean,
            positionMs: Long,
            durationMs: Long,
            artwork: ByteArray?,
        ) {
            val artworkPath = cacheWidgetArtwork(context, artwork, hasTrack)
            preferences(context).edit()
                .putString(KEY_TITLE, title)
                .putString(KEY_ARTIST, artist)
                .putBoolean(KEY_HAS_TRACK, hasTrack)
                .putBoolean(KEY_IS_PLAYING, isPlaying)
                .putLong(KEY_POSITION_MS, positionMs)
                .putLong(KEY_DURATION_MS, durationMs)
                .putString(KEY_ARTWORK_PATH, artworkPath)
                .apply()
            updateAll(context)
        }

        private fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, Tape88WidgetProvider::class.java)
            manager.getAppWidgetIds(component).forEach { id ->
                updateWidget(context, manager, id)
            }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
        ) {
            val state = preferences(context)
            val hasTrack = state.getBoolean(KEY_HAS_TRACK, false)
            val isPlaying = hasTrack && state.getBoolean(KEY_IS_PLAYING, false)
            val durationMs = state.getLong(KEY_DURATION_MS, 0L)
            val positionMs = state.getLong(KEY_POSITION_MS, 0L)
            val progress = if (durationMs <= 0L) {
                0
            } else {
                (positionMs.coerceIn(0L, durationMs).toDouble() / durationMs * 1000)
                    .roundToInt()
            }
            val artwork = state.getString(KEY_ARTWORK_PATH, null)?.let { path ->
                BitmapFactory.decodeFile(path)
            }

            val views = RemoteViews(context.packageName, R.layout.tape_88_widget).apply {
                setTextViewText(
                    R.id.widget_title,
                    if (hasTrack) state.getString(KEY_TITLE, "Unknown track") else "NO TAPE LOADED",
                )
                setTextViewText(
                    R.id.widget_artist,
                    if (hasTrack) state.getString(KEY_ARTIST, "Unknown artist") else "LOCAL ARCHIVE",
                )
                setTextViewText(
                    R.id.widget_deck_label,
                    if (isPlaying) "TAPE 88  •  PLAYING" else "TAPE 88  •  LOCAL DECK",
                )
                setInt(
                    R.id.widget_led,
                    "setBackgroundResource",
                    if (isPlaying) R.drawable.widget_led_active else R.drawable.widget_led_inactive,
                )
                setImageViewResource(
                    R.id.widget_play_pause,
                    mediaDrawable(
                        context,
                        if (isPlaying) "audio_service_pause" else "audio_service_play_arrow",
                    ),
                )
                setProgressBar(R.id.widget_progress, 1000, progress, false)
                if (artwork != null) {
                    setImageViewBitmap(R.id.widget_artwork, artwork)
                } else {
                    setImageViewResource(R.id.widget_artwork, R.mipmap.ic_launcher_foreground)
                }
                setOnClickPendingIntent(
                    R.id.widget_previous,
                    actionIntent(context, ACTION_PREVIOUS, 8801),
                )
                setOnClickPendingIntent(
                    R.id.widget_play_pause,
                    actionIntent(context, ACTION_PLAY_PAUSE, 8802),
                )
                setOnClickPendingIntent(
                    R.id.widget_next,
                    actionIntent(context, ACTION_NEXT, 8803),
                )
            }
            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launchIntent ->
                val openApp = PendingIntent.getActivity(
                    context,
                    8800,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, openApp)
                views.setOnClickPendingIntent(R.id.widget_cassette_area, openApp)
            }
            manager.updateAppWidget(widgetId, views)
        }

        private fun actionIntent(context: Context, action: String, requestCode: Int): PendingIntent =
            PendingIntent.getBroadcast(
                context,
                requestCode,
                Intent(context, Tape88WidgetProvider::class.java).setAction(action),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        private fun sendMediaKey(context: Context, keyCode: Int) {
            listOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP).forEach { action ->
                val intent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                    setClassName(
                        context.packageName,
                        "com.ryanheise.audioservice.MediaButtonReceiver",
                    )
                    putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(action, keyCode))
                }
                context.sendBroadcast(intent)
            }
        }

        @SuppressLint("DiscouragedApi")
        private fun mediaDrawable(context: Context, name: String): Int =
            context.resources.getIdentifier(name, "drawable", context.packageName)

        private fun cacheWidgetArtwork(
            context: Context,
            bytes: ByteArray?,
            hasTrack: Boolean,
        ): String? {
            val target = context.cacheDir.resolve("widget_artwork.jpg")
            if (!hasTrack || bytes == null || bytes.isEmpty()) {
                target.delete()
                return null
            }
            return try {
                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
                target.outputStream().use { output ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 88, output)
                }
                bitmap.recycle()
                target.absolutePath
            } catch (_: Exception) {
                null
            }
        }

        private fun preferences(context: Context) =
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
    }
}
