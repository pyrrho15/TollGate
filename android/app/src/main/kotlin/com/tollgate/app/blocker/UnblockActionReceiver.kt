package com.tollgate.app.blocker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Backs the buttons and the "swipe away" handling of the unblock notification.
 *
 *  - [ACTION_REBLOCK]: the user tapped "Block now" — end the break immediately.
 *  - [ACTION_REPOST]: the user dismissed the notification — put it straight back so the
 *    reminder is genuinely pinned while a break is running.
 */
class UnblockActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_REBLOCK -> {
                UnblockSchedule.stop(context)
                KeepAliveService.refresh(context)
                BlockerEvents.emit(BlockerController(context).currentState())
            }

            ACTION_REPOST -> {
                KeepAliveService.refresh(context)
            }
        }
    }

    companion object {
        const val ACTION_REBLOCK = "com.tollgate.app.action.REBLOCK"
        const val ACTION_REPOST = "com.tollgate.app.action.REPOST_STATUS"
    }
}
