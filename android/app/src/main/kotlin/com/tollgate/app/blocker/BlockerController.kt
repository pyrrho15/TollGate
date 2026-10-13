package com.tollgate.app.blocker

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles method channel calls from Dart and exposes the current blocker state.
 */
class BlockerController(private val context: Context) {

    fun currentState(): Map<String, Any?> = mapOf(
        "accessibilityEnabled" to isAccessibilityEnabled(context),
        "masterEnabled" to BlockerPrefs.isMasterEnabled(context),
        "targets" to SupportedTargets.all.map { target ->
            mapOf(
                "id" to target.id,
                "name" to target.displayName,
                "packageName" to target.packageName,
                "description" to target.description,
                "enabled" to BlockerPrefs.isTargetEnabled(context, target.id),
            )
        },
    )

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getState" -> result.success(currentState())

            "setMasterEnabled" -> {
                val enabled = call.arguments as? Boolean ?: false
                BlockerPrefs.setMasterEnabled(context, enabled)
                if (enabled) KeepAliveService.start(context) else KeepAliveService.stop(context)
                result.success(currentState())
            }

            "setTargetEnabled" -> {
                val args = call.arguments as? Map<*, *>
                val id = args?.get("id") as? String
                val enabled = args?.get("enabled") as? Boolean ?: false
                if (id != null) BlockerPrefs.setTargetEnabled(context, id, enabled)
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
