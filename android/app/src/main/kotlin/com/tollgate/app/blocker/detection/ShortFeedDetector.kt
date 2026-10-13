package com.tollgate.app.blocker.detection

import android.view.accessibility.AccessibilityNodeInfo
import com.tollgate.app.blocker.TargetApp

/**
 * Pure, side-effect free detection. Kept free of accessibility plumbing so the matching
 * rules can be reasoned about (and later unit tested) in isolation from the live tree.
 */
object ShortFeedDetector {

    private const val MAX_NODES = 800
    private const val MAX_DEPTH = 25

    /**
     * True when a full view id (e.g. `pkg:id/reel_recycler`) identifies the target's
     * full-screen player rather than a shelf/preview.
     */
    fun matchesViewId(viewId: String, target: TargetApp): Boolean {
        val suffix = viewId.substringAfterLast('/')
        if (target.excludedViewIdMarkers.any { suffix.contains(it) }) return false
        return target.playerViewIdMarkers.any { suffix.contains(it) }
    }

    /** True when the current screen is the blocked short-form surface for [target]. */
    fun isBlockedFeed(root: AccessibilityNodeInfo?, target: TargetApp): Boolean {
        if (root == null) return false

        // Fast path: let the framework resolve the ids it knows about.
        for (marker in target.playerViewIdMarkers) {
            val found = root.findAccessibilityNodeInfosByViewId("${target.packageName}:id/$marker")
            if (!found.isNullOrEmpty()) {
                val name = found[0].viewIdResourceName
                if (name == null || matchesViewId(name, target)) return true
            }
        }

        // Backstop: bounded walk, in case the player container has a marker we do not
        // resolve by exact id, or ids shift between app releases.
        return walk(root, target, depth = 0, visited = intArrayOf(0))
    }

    private fun walk(
        node: AccessibilityNodeInfo?,
        target: TargetApp,
        depth: Int,
        visited: IntArray,
    ): Boolean {
        if (node == null || depth > MAX_DEPTH || visited[0] > MAX_NODES) return false
        visited[0]++

        val viewId = node.viewIdResourceName
        if (viewId != null && matchesViewId(viewId, target)) return true

        for (i in 0 until node.childCount) {
            if (walk(node.getChild(i), target, depth + 1, visited)) return true
        }
        return false
    }
}
