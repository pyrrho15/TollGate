package com.tollgate.app.blocker

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.provider.Settings
import com.tollgate.app.blocker.stats.UsageStatsTracker
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles method channel calls from Dart and exposes the current blocker state.
 *
 * This is also the enforcement point for the commitment rules: disabling a feed or
 * starting a break is refused here unless the phrase matches and the schedule allows it.
 */
class BlockerController(private val context: Context) {

    fun currentState(): Map<String, Any?> = mapOf(
        "accessibilityEnabled" to isAccessibilityEnabled(context),
        "masterEnabled" to BlockerPrefs.isMasterEnabled(context),
        "notificationsEnabled" to notificationsEnabled(context),
        "targets" to SupportedTargets.all.map { target ->
            mapOf(
                "id" to target.id,
                "name" to target.displayName,
                "packageName" to target.packageName,
                "description" to target.description,
                "enabled" to BlockerPrefs.isTargetEnabled(context, target.id),
            )
        },
        "unblock" to UnblockSchedule.snapshot(context),
    )

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getState" -> result.success(currentState())

            "getStats" -> {
                val stats = UsageStatsTracker.snapshot(context).toMutableMap()
                stats["unblock"] = UnblockSchedule.snapshot(context)
                result.success(stats)
            }

            "setMasterEnabled" -> {
                val enabled = call.arguments as? Boolean ?: false
                BlockerPrefs.setMasterEnabled(context, enabled)
                if (enabled) KeepAliveService.start(context) else KeepAliveService.stop(context)
                emitState()
                result.success(currentState())
            }

            "setTargetEnabled" -> setTargetEnabled(call, result)

            "requestUnblock" -> requestUnblock(call, result)

            "reblockNow" -> {
                UnblockSchedule.stop(context)
                KeepAliveService.refresh(context)
                emitState()
                result.success(currentState())
            }

            "openAccessibilitySettings" -> {
                context.startActivity(
                    Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
                result.success(true)
            }

            "openNotificationSettings" -> {
                val intent = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                } else {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        .setData(android.net.Uri.parse("package:${context.packageName}"))
                }
                context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Turning a feed *on* is free. Turning it *off* is a commitment decision: it needs
     * the phrase and is refused outright during the hard schedule.
     */
    private fun setTargetEnabled(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val id = args?.get("id") as? String
        val enabled = args?.get("enabled") as? Boolean ?: true
        if (id == null) {
            result.error("bad_request", "Missing target id.", null)
            return
        }

        if (!enabled) {
            if (UnblockSchedule.isHardBlockWindow()) {
                result.error("hard_window", "Feeds can't be changed between 12am and 10am.", null)
                return
            }
            val phrase = args["phrase"] as? String
            if (!UnblockSchedule.phrasesMatch(phrase)) {
                result.error("phrase_mismatch", "That doesn't match the phrase.", null)
                return
            }
        }

        BlockerPrefs.setTargetEnabled(context, id, enabled)
        emitState()
        result.success(currentState())
    }

    private fun requestUnblock(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val phrase = args?.get("phrase") as? String

        if (!UnblockSchedule.phrasesMatch(phrase)) {
            result.error("phrase_mismatch", "That doesn't match the phrase.", null)
            return
        }
        if (UnblockSchedule.isHardBlockWindow()) {
            result.error("hard_window", "Breaks aren't allowed between 12am and 10am.", null)
            return
        }
        if (UnblockSchedule.remainingMs(context) <= 0L) {
            result.error("budget_exhausted", "Today's break time is used up.", null)
            return
        }

        val started = UnblockSchedule.start(context)
        if (!started) {
            result.error("unavailable", "Could not start a break right now.", null)
            return
        }

        KeepAliveService.refresh(context)
        emitState()
        result.success(currentState())
    }

    private fun emitState() = BlockerEvents.emit(currentState())

    /** Whether the user has allowed notifications (needed for the pinned reminder). */
    private fun notificationsEnabled(context: Context): Boolean {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.N) return true
        val manager = context.getSystemService(android.app.NotificationManager::class.java)
            ?: return false
        return manager.areNotificationsEnabled()
    }

    companion object {
        /** True only when the OS reports our accessibility service as enabled. */
        fun isAccessibilityEnabled(context: Context): Boolean {
            val manager = context.getSystemService(Context.ACCESSIBILITY_SERVICE)
                as? android.view.accessibility.AccessibilityManager ?: return false
            val expected = ShortVideoBlockerService::class.java.name
            return manager
                .getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
                .any { info ->
                    val serviceInfo = info.resolveInfo?.serviceInfo ?: return@any false
                    serviceInfo.packageName == context.packageName &&
                        serviceInfo.name == expected
                }
        }
    }
}
