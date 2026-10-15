package com.tollgate.app.blocker.detection

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo
import com.tollgate.app.blocker.StructureRule
import com.tollgate.app.blocker.TargetApp

/**
 * Pure, side-effect free detection. Kept free of accessibility plumbing so the matching
 * rules can be reasoned about (and later unit tested) in isolation from the live tree.
 */
object ShortFeedDetector {

    private const val MAX_NODES = 1200
    private const val MAX_DEPTH = 25

    /** Depth guard for the nested structural signature, which is not node-counted. */
    private const val MAX_STRUCTURE_DEPTH = 12

    /**
     * True when a full view id (e.g. `pkg:id/reel_recycler`) identifies the target's
     * full-screen player rather than a shelf/preview.
     */
    fun matchesViewId(viewId: String, target: TargetApp): Boolean {
        val suffix = viewId.substringAfterLast('/')
        if (target.excludedViewIdMarkers.any { suffix.contains(it) }) return false
        return target.playerViewIdMarkers.any { suffix.contains(it) }
    }

    /**
     * True when the current screen is the blocked short-form surface for [target].
     *
     * [screenWidth] / [screenHeight] are the physical screen size, used only by the
     * structural fallback; pass 0 to skip it.
     */
    fun isBlockedFeed(
        root: AccessibilityNodeInfo?,
        target: TargetApp,
        screenWidth: Int,
        screenHeight: Int,
    ): Boolean {
        if (root == null) return false

        // Fast path: let the framework resolve the ids it knows about.
        for (packageName in target.packageNames) {
            for (marker in target.playerViewIdMarkers) {
                val found = root.findAccessibilityNodeInfosByViewId("$packageName:id/$marker")
                if (!found.isNullOrEmpty()) {
                    val name = found[0].viewIdResourceName
                    if (name == null || matchesViewId(name, target)) return true
                }
            }
        }

        val hasStructuralRule = target.structure != null && screenWidth > 0 && screenHeight > 0
        if (target.playerViewIdMarkers.isEmpty() &&
            target.contentDescriptions.isEmpty() &&
            target.contentDescriptionPrefixes.isEmpty() &&
            !hasStructuralRule
        ) return false

        // Backstop: bounded walk, in case the player container has a marker we do not
        // resolve by exact id, or ids shift between app releases.
        return walk(root, target, depth = 0, visited = intArrayOf(0), screenWidth, screenHeight)
    }

    private fun walk(
        node: AccessibilityNodeInfo?,
        target: TargetApp,
        depth: Int,
        visited: IntArray,
        screenWidth: Int,
        screenHeight: Int,
    ): Boolean {
        if (node == null || depth > MAX_DEPTH || visited[0] > MAX_NODES) return false
        visited[0]++

        if (matchesNode(node, target, screenWidth, screenHeight)) return true

        for (i in 0 until node.childCount) {
            if (walk(node.getChild(i), target, depth + 1, visited, screenWidth, screenHeight)) return true
        }
        return false
    }

    private fun matchesNode(
        node: AccessibilityNodeInfo,
        target: TargetApp,
        screenWidth: Int,
        screenHeight: Int,
    ): Boolean {
        val viewId = node.viewIdResourceName
        if (viewId != null && target.playerViewIdMarkers.isNotEmpty() && matchesViewId(viewId, target)) {
            return true
        }

        val description = node.contentDescription?.toString()
        if (description != null) {
            if (target.contentDescriptions.any { it.equals(description, ignoreCase = true) }) return true
            if (target.contentDescriptionPrefixes.any { description.startsWith(it, ignoreCase = true) } &&
                (!target.requireSelectedForPrefix || node.isSelected)
            ) {
                return true
            }
        }

        val rule = target.structure
        if (rule != null && screenWidth > 0 && screenHeight > 0) {
            if (matchesStructure(node, rule, screenWidth, screenHeight, depth = 0)) return true
        }

        return false
    }

    private fun matchesStructure(
        node: AccessibilityNodeInfo,
        rule: StructureRule,
        screenWidth: Int,
        screenHeight: Int,
        depth: Int,
    ): Boolean {
        if (depth > MAX_STRUCTURE_DEPTH) return false
        if (!node.isVisibleToUser) return false

        val className = node.className?.toString()
        if (className == null || className !in rule.classNames) return false

        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        if (bounds.width().toFloat() / screenWidth < rule.minWidthFraction) return false
        if (bounds.height().toFloat() / screenHeight < rule.minHeightFraction) return false

        if (rule.requireScrollable && !node.isScrollable) return false
        if (rule.requireLongClickable && !node.isLongClickable) return false

        val descendant = rule.descendant ?: return true
        return hasDescendantMatching(node, descendant, screenWidth, screenHeight, depth)
    }

    /** True if any node below [parent] (at any depth) satisfies [rule]. */
    private fun hasDescendantMatching(
        parent: AccessibilityNodeInfo,
        rule: StructureRule,
        screenWidth: Int,
        screenHeight: Int,
        depth: Int,
    ): Boolean {
        if (depth > MAX_STRUCTURE_DEPTH) return false
        for (i in 0 until parent.childCount) {
            val child = parent.getChild(i) ?: continue
            if (matchesStructure(child, rule, screenWidth, screenHeight, depth + 1)) return true
            if (hasDescendantMatching(child, rule, screenWidth, screenHeight, depth + 1)) return true
        }
        return false
    }
}
