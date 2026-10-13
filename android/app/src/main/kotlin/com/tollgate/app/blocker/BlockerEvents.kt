package com.tollgate.app.blocker

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Single broadcast point for blocker state. The accessibility service can live in a
 * different process than the activity, so anything that changes state emits here and
 * MainActivity forwards it to the Dart event stream.
 */
object BlockerEvents {

    private val main = Handler(Looper.getMainLooper())

    @Volatile
    var sink: EventChannel.EventSink? = null

    fun emit(payload: Any) {
        val current = sink ?: return
        if (Looper.myLooper() == Looper.getMainLooper()) {
            current.success(payload)
        } else {
            main.post { sink?.success(payload) }
        }
    }
}
