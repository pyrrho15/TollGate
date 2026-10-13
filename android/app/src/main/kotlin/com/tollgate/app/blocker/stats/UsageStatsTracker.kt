package com.tollgate.app.blocker.stats

import android.content.Context
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import com.tollgate.app.blocker.SupportedTargets
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Counts how long each supported app is in the foreground, and how many times we
 * blocked a Short/Reel, using only the accessibility events we already receive.
 *
 * No extra permission is needed: the service is scoped to YouTube and Instagram, so
 * the only thing this ever sees is those two packages. Totals are kept per day in
 * SharedPreferences and read back by the UI through the method channel.
 *
 * Time is measured as a *session*: it starts when the app becomes active and ends
 * when it stops being active (confirmed by a 2-second poll of the active window) or
 * after a short idle timeout. Sessions are attributed to the day they started and
 * are deliberately an approximation — see the note on the Stats screen.
 */
object UsageStatsTracker {

    private const val FILE = "tollgate_stats"
    private const val PREFIX = "v1"
    private const val RETAIN_DAYS = 30

    /** How long a session survives without any signal that the app is still active. */
    private const val IDLE_TIMEOUT_MS = 15_000L

    private const val METRIC_TIME = "time"
    private const val METRIC_BLOCKS = "blocks"
    private const val METRIC_OPENS = "opens"

    private val dayFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
    private val lock = Any()

    // Active session state. All access happens on the process main thread.
    private var activeTargetId: String? = null
    private var sessionDate: String? = null
    private var sessionStartMs = 0L
    private var lastSignalMs = 0L

    private fun prefs(context: Context) =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    private fun today(): String = dayFormat.format(Date())

    private fun key(date: String, targetId: String, metric: String) =
        "$PREFIX|$date|$targetId|$metric"

    // ---------------------------------------------------------------- signals

    /**
     * Called for every window-state/content change the service receives. Keeps the
     * session for [packageName] alive; only supported packages ever reach us.
     */
    fun onAccessibilityEvent(context: Context, packageName: String?, eventType: Int) {
        if (eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) return
        val target = packageName?.let { SupportedTargets.forPackage(it) } ?: return
        signal(context, target.id)
    }

    /**
     * Called on a timer with the package of the currently focused window, or null when
     * it cannot be determined. This is what keeps a session alive during quiet
     * periods (a video playing with no UI updates) and ends it promptly on leaving.
     */
    fun onTick(context: Context, activePackage: String?) {
        val targetId = activePackage?.let { SupportedTargets.forPackage(it)?.id }
        val now = SystemClock.uptimeMillis()
        synchronized(lock) {
            if (targetId != null) {
                beginOrContinue(context, targetId, now)
            } else if (activeTargetId != null && now - lastSignalMs > IDLE_TIMEOUT_MS) {
                commit(context)
            }
        }
    }

    private fun signal(context: Context, targetId: String) {
        val now = SystemClock.uptimeMillis()
        synchronized(lock) {
            beginOrContinue(context, targetId, now)
        }
    }

    private fun beginOrContinue(context: Context, targetId: String, now: Long) {
        if (activeTargetId != targetId) {
            commit(context)
            activeTargetId = targetId
            sessionDate = today()
            sessionStartMs = now
            add(context, sessionDate!!, targetId, METRIC_OPENS, 1L)
        }
        lastSignalMs = now
    }

    // ------------------------------------------------------------------ events

    /** Records a blocked Short/Reel for [targetId]. */
    fun onBlocked(context: Context, targetId: String) {
        synchronized(lock) {
            add(context, today(), targetId, METRIC_BLOCKS, 1L)
        }
    }

    /** Ends any active session (screen off, service destroyed, …). */
    fun flush(context: Context) {
        synchronized(lock) { commit(context) }
    }

    /** Ends the active session and adds its duration to the running totals. */
    private fun commit(context: Context) {
        val targetId = activeTargetId ?: return
        val date = sessionDate ?: today()
        val duration = lastSignalMs - sessionStartMs
        if (duration > 0) add(context, date, targetId, METRIC_TIME, duration)
        activeTargetId = null
        sessionDate = null
        sessionStartMs = 0L
        lastSignalMs = 0L
    }

    private fun add(context: Context, date: String, targetId: String, metric: String, delta: Long) {
        val prefs = prefs(context)
        val key = key(date, targetId, metric)
        prefs.edit().putLong(key, prefs.getLong(key, 0L) + delta).apply()
    }

    // --------------------------------------------------------------- retention

    /** Drops anything older than [RETAIN_DAYS]. Cheap; runs when the service connects. */
    fun prune(context: Context) {
        val prefs = prefs(context)
        val cutoff = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, -RETAIN_DAYS)
        }.time
        val editor = prefs.edit()
        for (key in prefs.all.keys) {
            val parts = key.split('|')
            if (parts.size < 4 || parts[0] != PREFIX) continue
            val date = runCatching { dayFormat.parse(parts[1]) }.getOrNull() ?: continue
            if (date.before(cutoff)) editor.remove(key)
        }
        editor.apply()
    }

    // ----------------------------------------------------------------- reading

    /** Snapshot of today's totals per target plus the last seven days. */
    fun snapshot(context: Context): Map<String, Any?> {
        val prefs = prefs(context)
        val today = today()

        // Fold the in-progress session into today's number so the UI feels live.
        val liveTargetId: String?
        val liveMs: Long
        synchronized(lock) {
            liveTargetId = if (sessionDate == today) activeTargetId else null
            liveMs = (lastSignalMs - sessionStartMs).coerceAtLeast(0L)
        }

        val targets = SupportedTargets.all.map { target ->
            var timeMs = prefs.getLong(key(today, target.id, METRIC_TIME), 0L)
            if (target.id == liveTargetId) timeMs += liveMs
            mapOf(
                "id" to target.id,
                "name" to target.displayName,
                "timeMs" to timeMs,
                "blocks" to prefs.getLong(key(today, target.id, METRIC_BLOCKS), 0L),
                "opens" to prefs.getLong(key(today, target.id, METRIC_OPENS), 0L),
            )
        }

        val history = (6 downTo 0).map { offset ->
            val date = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, -offset)
            }.let { dayFormat.format(it.time) }

            var timeMs = 0L
            var blocks = 0L
            for (target in SupportedTargets.all) {
                timeMs += prefs.getLong(key(date, target.id, METRIC_TIME), 0L)
                blocks += prefs.getLong(key(date, target.id, METRIC_BLOCKS), 0L)
            }
            if (date == today) {
                // include the live session in today's bar
                for (target in SupportedTargets.all) {
                    if (target.id == liveTargetId) timeMs += liveMs
                }
            }
            mapOf("date" to date, "timeMs" to timeMs, "blocks" to blocks)
        }

        return mapOf(
            "today" to today,
            "targets" to targets,
            "history" to history,
        )
    }
}
