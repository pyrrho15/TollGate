package com.tollgate.app

import android.content.Intent
import android.os.Bundle
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

    override fun onResume() {
        super.onResume()
        // Reflect accessibility permission changes made while we were in Settings.
        BlockerEvents.emit(controller.currentState())
    }

    companion object {
        const val METHOD_CHANNEL = "com.tollgate.app/blocker"
        const val EVENT_CHANNEL = "com.tollgate.app/blocker_events"
    }
}
