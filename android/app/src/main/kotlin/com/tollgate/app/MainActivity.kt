package com.tollgate.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.tollgate.app.blocker.BlockerController
import com.tollgate.app.blocker.BlockerEvents

class MainActivity : FlutterActivity() {

    private lateinit var controller: BlockerController

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        controller = BlockerController(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result -> controller.handle(call, result) }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    BlockerEvents.sink = events
                    events?.success(controller.currentState())
                }

                override fun onCancel(arguments: Any?) {
                    BlockerEvents.sink = null
                }
            })
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermissionIfNeeded()
    }

    override fun onResume() {
        super.onResume()
        // Reflect accessibility permission changes made while we were in Settings.
        BlockerEvents.emit(controller.currentState())
    }

    /**
     * The pinned break reminder needs notification permission; without it Android 13+
     * silently drops the notification (and the foreground-service notice too). Ask once
     * on first launch — the UI also offers a button if the user later revokes it.
     */
    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_NOTIFICATIONS,
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_NOTIFICATIONS) {
            BlockerEvents.emit(BlockerController(applicationContext).currentState())
        }
    }

    companion object {
        const val METHOD_CHANNEL = "com.tollgate.app/blocker"
        const val EVENT_CHANNEL = "com.tollgate.app/blocker_events"
        private const val REQUEST_NOTIFICATIONS = 9001
    }
}
