package com.rugdraiger.rugdraiger_player

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.KeyEvent

class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != PlayerWidgetProvider.ACTION_MEDIA) return

        val action = intent.getStringExtra(PlayerWidgetProvider.EXTRA_MEDIA_ACTION) ?: return
        val keyCode = when (action) {
            "play_pause" -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
            "prev" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            else -> return
        }

        sendMediaKey(context, keyCode)
        PlayerWidgetProvider.updateAll(context)
    }

    private fun sendMediaKey(context: Context, keyCode: Int) {
        val component = ComponentName(
            context.packageName,
            "com.ryanheise.audioservice.MediaButtonReceiver",
        )

        for (eventAction in intArrayOf(KeyEvent.ACTION_DOWN, KeyEvent.ACTION_UP)) {
            val mediaIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                this.component = component
                putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(eventAction, keyCode))
            }
            context.sendBroadcast(mediaIntent)
        }
    }
}
