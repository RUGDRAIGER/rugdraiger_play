package com.rugdraiger.rugdraiger_player

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import java.io.File

class PlayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context))
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            updateAll(context)
        }
    }

    companion object {
        const val ACTION_REFRESH = "com.rugdraiger.rugdraiger_player.WIDGET_REFRESH"
        const val ACTION_MEDIA = "com.rugdraiger.rugdraiger_player.WIDGET_MEDIA"
        const val EXTRA_MEDIA_ACTION = "media_action"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, PlayerWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return

            val views = buildViews(context)
            for (id in ids) {
                manager.updateAppWidget(id, views)
            }
        }

        private fun buildViews(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_player)

            if (!WidgetHelper.isActive(context)) {
                views.setTextViewText(R.id.widget_title, "Rugdraiger Play")
                views.setTextViewText(R.id.widget_artist, "Toca una canción para empezar")
                views.setTextViewText(R.id.widget_queue, "")
                views.setImageViewResource(R.id.widget_artwork, R.mipmap.ic_launcher)
                views.setImageViewResource(R.id.widget_artwork_bg, R.mipmap.ic_launcher)
                views.setProgressBar(R.id.widget_progress, 1000, 0, false)
                views.setImageViewResource(R.id.widget_btn_play_pause, R.drawable.ic_widget_play)
            } else {
                views.setTextViewText(R.id.widget_title, WidgetHelper.title(context))
                views.setTextViewText(R.id.widget_artist, WidgetHelper.artist(context))

                val queueSize = WidgetHelper.queueSize(context)
                val queueIndex = WidgetHelper.queueIndex(context)
                val queueText = if (queueSize > 1) {
                    "Cola ${queueIndex + 1} de $queueSize"
                } else {
                    WidgetHelper.album(context)
                }
                views.setTextViewText(R.id.widget_queue, queueText)

                val duration = WidgetHelper.durationMs(context).coerceAtLeast(1)
                val progress = ((WidgetHelper.positionMs(context).toFloat() / duration) * 1000).toInt()
                    .coerceIn(0, 1000)
                views.setProgressBar(R.id.widget_progress, 1000, progress, false)

                val playing = WidgetHelper.isPlaying(context)
                views.setImageViewResource(
                    R.id.widget_btn_play_pause,
                    if (playing) R.drawable.ic_widget_pause else R.drawable.ic_widget_play,
                )

                val artPath = WidgetHelper.artworkPath(context)
                if (!artPath.isNullOrBlank() && File(artPath).exists()) {
                    try {
                        val bitmap = BitmapFactory.decodeFile(artPath)
                        if (bitmap != null) {
                            views.setImageViewBitmap(R.id.widget_artwork, bitmap)
                            views.setImageViewBitmap(R.id.widget_artwork_bg, bitmap)
                            views.setViewVisibility(R.id.widget_scrim, View.VISIBLE)
                        } else {
                            setDefaultArtwork(views)
                        }
                    } catch (_: Exception) {
                        setDefaultArtwork(views)
                    }
                } else {
                    setDefaultArtwork(views)
                }
            }

            views.setOnClickPendingIntent(
                R.id.widget_root,
                pendingLaunch(context, 100),
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_prev,
                pendingMedia(context, "prev", 101),
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_play_pause,
                pendingMedia(context, "play_pause", 102),
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_next,
                pendingMedia(context, "next", 103),
            )

            return views
        }

        private fun setDefaultArtwork(views: RemoteViews) {
            views.setImageViewResource(R.id.widget_artwork, R.mipmap.ic_launcher)
            views.setImageViewResource(R.id.widget_artwork_bg, R.mipmap.ic_launcher)
            views.setViewVisibility(R.id.widget_scrim, View.VISIBLE)
        }

        private fun pendingLaunch(context: Context, requestCode: Int): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun pendingMedia(context: Context, action: String, requestCode: Int): PendingIntent {
            val intent = Intent(context, WidgetActionReceiver::class.java).apply {
                this.action = ACTION_MEDIA
                putExtra(EXTRA_MEDIA_ACTION, action)
            }
            return PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
