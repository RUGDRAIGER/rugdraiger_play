package com.rugdraiger.rugdraiger_player

import android.content.Context
import android.content.SharedPreferences

object WidgetHelper {
    private const val PREFS = "rugdraiger_widget"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun saveState(context: Context, args: Map<*, *>) {
        prefs(context).edit()
            .putString("title", args["title"] as? String ?: "")
            .putString("artist", args["artist"] as? String ?: "")
            .putString("album", args["album"] as? String ?: "")
            .putString("artworkPath", args["artworkPath"] as? String)
            .putBoolean("isPlaying", args["isPlaying"] as? Boolean ?: false)
            .putInt("positionMs", (args["positionMs"] as? Number)?.toInt() ?: 0)
            .putInt("durationMs", (args["durationMs"] as? Number)?.toInt() ?: 0)
            .putInt("queueSize", (args["queueSize"] as? Number)?.toInt() ?: 0)
            .putInt("queueIndex", (args["queueIndex"] as? Number)?.toInt() ?: 0)
            .putBoolean("active", true)
            .apply()
    }

    fun clearState(context: Context) {
        prefs(context).edit()
            .putBoolean("active", false)
            .remove("title")
            .remove("artist")
            .remove("album")
            .remove("artworkPath")
            .apply()
    }

    fun isActive(context: Context): Boolean = prefs(context).getBoolean("active", false)

    fun title(context: Context): String = prefs(context).getString("title", "Rugdraiger Play") ?: ""

    fun artist(context: Context): String = prefs(context).getString("artist", "") ?: ""

    fun album(context: Context): String = prefs(context).getString("album", "") ?: ""

    fun artworkPath(context: Context): String? = prefs(context).getString("artworkPath", null)

    fun isPlaying(context: Context): Boolean = prefs(context).getBoolean("isPlaying", false)

    fun positionMs(context: Context): Int = prefs(context).getInt("positionMs", 0)

    fun durationMs(context: Context): Int = prefs(context).getInt("durationMs", 0)

    fun queueSize(context: Context): Int = prefs(context).getInt("queueSize", 0)

    fun queueIndex(context: Context): Int = prefs(context).getInt("queueIndex", 0)
}
