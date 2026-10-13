package com.tollgate.app.blocker

import android.accessibilityservice.AccessibilityService
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import com.tollgate.app.R
import com.tollgate.app.blocker.detection.ShortFeedDetector

/**
 * The blocking engine. Scoped by `res/xml/accessibility_service_config.xml` to the
 * packages we support, so the OS never hands us events from any other app.
 *
 * On a blocked surface we do the least invasive thing possible: press Back and leave.
 */
class ShortVideoBlockerService : AccessibilityService() {

    private var lastBlockAt = 0L
    private var lastAnalyzeAt = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        BlockerEvents.emit(BlockerController(this).currentState())
        if (BlockerPrefs.isMasterEnabled(this)) KeepAliveService.start(this)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (!BlockerPrefs.isMasterEnabled(this)) return

        val eventType = event.eventType
        if (eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) return

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
        Toast.makeText(this, getString(R.string.blocked_toast, target.displayName), Toast.LENGTH_SHORT).show()
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

    override fun onInterrupt() = Unit

    companion object {
        private const val ANALYZE_INTERVAL_MS = 120L
        private const val BLOCK_COOLDOWN_MS = 700L
    }
}
