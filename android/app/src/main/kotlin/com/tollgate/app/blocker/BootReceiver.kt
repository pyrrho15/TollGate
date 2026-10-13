package com.tollgate.app.blocker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-arms the keep-alive service after a reboot if blocking was left on. Android
 * restores enabled accessibility services itself on boot; this only restarts the
 * process-keeping companion.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED &&
            BlockerPrefs.isMasterEnabled(context)
        ) {
            KeepAliveService.start(context)
        }
    }
}
