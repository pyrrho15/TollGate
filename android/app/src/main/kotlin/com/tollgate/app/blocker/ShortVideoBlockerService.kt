package com.tollgate.app.blocker

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import androidx.core.content.ContextCompat
import com.tollgate.app.R
import com.tollgate.app.blocker.detection.ShortFeedDetector
import com.tollgate.app.blocker.stats.UsageStatsTracker

/**
 * The blocking engine. Scoped by `res/xml/accessibility_service_config.xml` to the
 * packages we support, so the OS never hands us events from any other app.
 *
 * On a blocked surface we do the least invasive thing possible: press Back and leave.
 * The same events also feed [UsageStatsTracker], which is why the Stats screen needs
 * no extra permission.
 */
class ShortVideoBlockerService : AccessibilityService() {

    private var lastBlockAt = 0L
    private var lastAnalyzeAt = 0L

    private val handler = Handler(Looper.getMainLooper())
    private var statsTickerRunning = false

    private val statsTicker = object : Runnable {
        override fun run() {
            val service = this@ShortVideoBlockerService
            UsageStatsTracker.onTick(service, activePackageName())

            // End a break that the clock or the budget has run out of, and keep the
            // pinned "you're unblocked" notice alive while one is running.
            val changed = UnblockSchedule.enforce(service)
            if (changed || UnblockSchedule.isUnblockActive(service)) {
                KeepAliveService.refresh(service)
            }
            if (changed) BlockerEvents.emit(BlockerController(service).currentState())

            handler.postDelayed(this, STATS_TICK_MS)
        }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                UsageStatsTracker.flush(this@ShortVideoBlockerService)
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        startStatsTracking()
        BlockerEvents.emit(BlockerController(this).currentState())
        if (BlockerPrefs.isMasterEnabled(this)) KeepAliveService.start(this)
    }

    private fun startStatsTracking() {
        if (statsTickerRunning) return
        statsTickerRunning = true
        UsageStatsTracker.prune(this)
        UnblockSchedule.prune(this)
        ContextCompat.registerReceiver(
            this,
            screenReceiver,
            IntentFilter(Intent.ACTION_SCREEN_OFF),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        handler.postDelayed(statsTicker, STATS_TICK_MS)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val eventType = event.eventType
        if (eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) return

        // Stats are counted before the blocking checks so they keep working even when
        // the master switch (i.e. blocking) is paused.
        UsageStatsTracker.onAccessibilityEvent(this, event.packageName?.toString(), eventType)

        if (!BlockerPrefs.isMasterEnabled(this)) return

        // A break is running (and allowed): leave the user alone.
        if (UnblockSchedule.isUnblockActive(this)) return

        val packageName = event.packageName?.toString() ?: return
        val target = SupportedTargets.forPackage(packageName) ?: return
        if (!BlockerPrefs.isTargetEnabled(this, target.id)) return

        // TYPE_WINDOW_CONTENT_CHANGED fires constantly while scrolling. Analysing the
        // tree on every one of them would burn CPU and battery, so cap the rate.
        val now = SystemClock.uptimeMillis()
        if (now - lastAnalyzeAt < ANALYZE_INTERVAL_MS) return
        lastAnalyzeAt = now

        // A single navigation fires a storm of events. Without this, chained Back
        // presses would overshoot and exit the app entirely.
        if (now - lastBlockAt < BLOCK_COOLDOWN_MS) return

        val root = resolveRoot(event) ?: return
        if (!ShortFeedDetector.isBlockedFeed(root, target)) return

        lastBlockAt = now
        performGlobalAction(GLOBAL_ACTION_BACK)
        UsageStatsTracker.onBlocked(this, target.id)
        Toast.makeText(this, getString(R.string.blocked_toast, target.displayName), Toast.LENGTH_SHORT).show()
    }

    /** Package of the currently focused window, or null if it can't be read. */
    private fun activePackageName(): String? = try {
        windows.firstOrNull { it.isActive }?.root?.packageName?.toString()
    } catch (e: Exception) {
        null
    }

    /**
     * `rootInActiveWindow` is frequently null mid-transition, which is exactly when a
     * player opens. Prefer the event source and climb to its root.
     */
    private fun resolveRoot(event: AccessibilityEvent): AccessibilityNodeInfo? {
        var node: AccessibilityNodeInfo? = event.source
        var guard = 0
        while (node != null && guard++ < 50) {
            if (node.parent == null) return node
            node = node.parent
        }
        return rootInActiveWindow
    }

    override fun onInterrupt() {
        UsageStatsTracker.flush(this)
    }

    override fun onDestroy() {
        UsageStatsTracker.flush(this)
        handler.removeCallbacks(statsTicker)
        if (statsTickerRunning) {
            try {
                unregisterReceiver(screenReceiver)
            } catch (e: Exception) {
                // Already unregistered; nothing to do.
            }
            statsTickerRunning = false
        }
        super.onDestroy()
    }

    companion object {
        private const val ANALYZE_INTERVAL_MS = 120L
        private const val BLOCK_COOLDOWN_MS = 700L
        private const val STATS_TICK_MS = 2_000L
    }
}
