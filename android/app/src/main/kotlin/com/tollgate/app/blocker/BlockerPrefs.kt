package com.tollgate.app.blocker

import android.content.Context

/**
 * The native side owns the settings. Dart never writes SharedPreferences directly:
 * it goes through the method channel, so there is exactly one source of truth that
 * both the UI and the background accessibility service read.
 */
object BlockerPrefs {

    private const val FILE = "tollgate_blocker"
    private const val KEY_MASTER = "master_enabled"
    private const val TARGET_PREFIX = "target_"

    private fun prefs(context: Context) =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun isMasterEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_MASTER, false)

    fun setMasterEnabled(context: Context, enabled: Boolean) =
        prefs(context).edit().putBoolean(KEY_MASTER, enabled).apply()

    /** Targets default to enabled so that flipping the master switch blocks everything. */
    fun isTargetEnabled(context: Context, id: String): Boolean =
        prefs(context).getBoolean(TARGET_PREFIX + id, true)

    fun setTargetEnabled(context: Context, id: String, enabled: Boolean) =
        prefs(context).edit().putBoolean(TARGET_PREFIX + id, enabled).apply()
}
