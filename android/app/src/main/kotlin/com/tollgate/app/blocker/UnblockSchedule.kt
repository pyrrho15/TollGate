package com.tollgate.app.blocker

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Owns the two commitment rules that make TollGate hard to switch off:
 *
 *  1. A **daily unblock budget** (90 minutes). "Disabling" the block is really a timed
 *     break that eats into the budget. Once it is spent, blocking is back for the day.
 *  2. A **hard schedule**: from 00:00 to 10:00 no break is possible at all, no matter
 *     how much budget is left.
 *
 * Everything is stored in SharedPreferences so the accessibility service, the UI and the
 * notification all read the same numbers. Wall-clock time (not uptime) is used, because
 * the budget resets at local midnight.
 */
object UnblockSchedule {

    /** 1.5 hours, per day. */
    const val DAILY_BUDGET_MS = 90L * 60L * 1000L

    /** Must match BlockerState/AppConstants on the Dart side. */
    const val PHRASE = "I'll regret this later"

    /** 00:00–10:00: blocking is mandatory and breaks are refused. */
    private const val HARD_BLOCK_START_HOUR = 0
    private const val HARD_BLOCK_END_HOUR = 10

    private const val FILE = "tollgate_unblock"
    private const val KEY_ACTIVE_SINCE = "active_since"
    private const val KEY_ACTIVE_DATE = "active_date"
    private const val USED_PREFIX = "used_"
    private const val SESSIONS_PREFIX = "sessions_"
    private const val RETAIN_DAYS = 400

    private val dayFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)

    private fun prefs(context: Context) =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun today(now: Long = System.currentTimeMillis()): String =
        dayFormat.format(Date(now))

    /**
     * Exact-match check, tolerant only of the two things every phone keyboard gets
     * wrong: leading/trailing spaces and "smart" apostrophes. Case must match.
     */
    fun phrasesMatch(input: String?): Boolean {
        if (input == null) return false
        val normalized = input.trim().replace('\u2019', '\'').replace('\u2018', '\'')
        return normalized == PHRASE
    }

    /** 12am–10am local: no break allowed, blocking is forced on. */
    fun isHardBlockWindow(now: Long = System.currentTimeMillis()): Boolean {
        val hour = Calendar.getInstance().apply { timeInMillis = now }.get(Calendar.HOUR_OF_DAY)
        return hour in HARD_BLOCK_START_HOUR until HARD_BLOCK_END_HOUR
    }

    fun usedMsToday(context: Context, now: Long = System.currentTimeMillis()): Long =
        prefs(context).getLong(USED_PREFIX + today(now), 0L)

    fun sessionsToday(context: Context, now: Long = System.currentTimeMillis()): Int =
        prefs(context).getInt(SESSIONS_PREFIX + today(now), 0)

    private fun activeSince(context: Context): Long =
        prefs(context).getLong(KEY_ACTIVE_SINCE, 0L)

    /** Used minutes today, including the session running right now. */
    private fun liveConsumedMs(context: Context, now: Long): Long {
        val base = usedMsToday(context, now)
        val since = activeSince(context)
        return if (since in 1 until now) base + (now - since) else base
    }

    /** Budget left today, ignoring the hard window (which pauses breaks, not the budget). */
    fun remainingMs(context: Context, now: Long = System.currentTimeMillis()): Long =
        (DAILY_BUDGET_MS - liveConsumedMs(context, now)).coerceAtLeast(0L)

    /** True while a break is actually running (not paused by the hard window or budget). */
    fun isUnblockActive(context: Context, now: Long = System.currentTimeMillis()): Boolean {
        if (activeSince(context) <= 0L) return false
        if (isHardBlockWindow(now)) return false
        return liveConsumedMs(context, now) < DAILY_BUDGET_MS
    }

    /** Starts a break. Returns false when the hard window or a spent budget refuses it. */
    fun start(context: Context, now: Long = System.currentTimeMillis()): Boolean {
        if (isHardBlockWindow(now)) return false
        if (activeSince(context) > 0L) return true
        if (remainingMs(context, now) <= 0L) return false

        prefs(context).edit()
            .putLong(KEY_ACTIVE_SINCE, now)
            .putString(KEY_ACTIVE_DATE, today(now))
            .putInt(SESSIONS_PREFIX + today(now), sessionsToday(context, now) + 1)
            .apply()
        return true
    }

    /** Ends the running break and commits its spent time to the day it started on. */
    fun stop(context: Context, now: Long = System.currentTimeMillis()) {
        val since = activeSince(context)
        if (since <= 0L) return

        val p = prefs(context)
        val date = p.getString(KEY_ACTIVE_DATE, null) ?: today(now)
        val usedKey = USED_PREFIX + date
        val elapsed = (now - since).coerceAtLeast(0L)
        val capped = (p.getLong(usedKey, 0L) + elapsed).coerceAtMost(DAILY_BUDGET_MS)

        p.edit()
            .putLong(usedKey, capped)
            .remove(KEY_ACTIVE_SINCE)
            .remove(KEY_ACTIVE_DATE)
            .apply()
    }

    /**
     * Called from the blocker ticker. Commits and ends a break that the clock or the
     * budget has invalidated. Returns true when the state actually changed, so callers
     * can refresh the notification.
     */
    fun enforce(context: Context, now: Long = System.currentTimeMillis()): Boolean {
        if (activeSince(context) <= 0L) return false
        if (isHardBlockWindow(now) || remainingMs(context, now) <= 0L) {
            stop(context, now)
            return true
        }
        return false
    }

    /** Drops day buckets older than [RETAIN_DAYS]. */
    fun prune(context: Context) {
        val p = prefs(context)
        val cutoff = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, -RETAIN_DAYS)
        }.time
        val editor = p.edit()
        for (key in p.all.keys) {
            val datePart = when {
                key.startsWith(USED_PREFIX) -> key.removePrefix(USED_PREFIX)
                key.startsWith(SESSIONS_PREFIX) -> key.removePrefix(SESSIONS_PREFIX)
                else -> continue
            }
            val date = runCatching { dayFormat.parse(datePart) }.getOrNull() ?: continue
            if (date.before(cutoff)) editor.remove(key)
        }
        editor.apply()
    }

    fun snapshot(context: Context, now: Long = System.currentTimeMillis()): Map<String, Any?> =
        mapOf(
            "budgetMs" to DAILY_BUDGET_MS,
            "usedMs" to liveConsumedMs(context, now),
            "remainingMs" to remainingMs(context, now),
            "sessions" to sessionsToday(context, now),
            "active" to isUnblockActive(context, now),
            "hardWindow" to isHardBlockWindow(now),
            "activeSince" to activeSince(context),
        )
}
