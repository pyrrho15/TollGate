package com.tollgate.app.blocker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.tollgate.app.MainActivity
import com.tollgate.app.R

/**
 * Keeps the app process out of Android's frozen state so the accessibility service is
 * not silently suspended after a while in the background (Android requires a visible
 * notification for that).
 *
 * The notification doubles as the commitment reminder: while a break is running it turns
 * into an ongoing "you're unblocked" notice that is re-posted whenever it is dismissed.
 */
class KeepAliveService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification())
        return START_STICKY
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    /** Re-posts the current notification (also silently restores a dismissed one). */
    fun post() {
        getSystemService(NotificationManager::class.java)
            ?.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun buildNotification(): Notification {
        ensureChannel()
        val unblocked = UnblockSchedule.isUnblockActive(this)

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setContentIntent(openAppIntent())
            .setDeleteIntent(repostIntent())

        if (unblocked) {
            val minutes = (UnblockSchedule.remainingMs(this) / 60_000L).coerceAtLeast(0L)
            builder
                .setContentTitle(getString(R.string.unblock_title, minutes))
                .setContentText(getString(R.string.unblock_text))
                .addAction(0, getString(R.string.unblock_action_reblock), reblockIntent())
        } else {
            builder
                .setContentTitle(getString(R.string.status_title))
                .setContentText(getString(R.string.status_text))
        }

        return builder.build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    getString(R.string.status_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                )
            )
        }
    }

    private fun openAppIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun repostIntent(): PendingIntent = PendingIntent.getBroadcast(
        this, 1,
        Intent(this, UnblockActionReceiver::class.java).setAction(UnblockActionReceiver.ACTION_REPOST),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun reblockIntent(): PendingIntent = PendingIntent.getBroadcast(
        this, 2,
        Intent(this, UnblockActionReceiver::class.java).setAction(UnblockActionReceiver.ACTION_REBLOCK),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    companion object {
        private const val TAG = "TollGateKeepAlive"
        private const val CHANNEL_ID = "tollgate_status"
        private const val NOTIFICATION_ID = 1001

        @Volatile
        private var instance: KeepAliveService? = null

        /** Posts the current notification, starting the service if it is not running. */
        fun refresh(context: Context) {
            val service = instance
            if (service != null) service.post() else start(context)
        }

        fun start(context: Context) {
            val intent = Intent(context, KeepAliveService::class.java)
            // Android 12+ forbids starting a foreground service from the background and
            // throws. This is best-effort: if the OS refuses, the accessibility service
            // still works, we just lose the anti-freeze protection for this round.
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.w(TAG, "Could not start keep-alive service: ${e.message}")
            }
        }

        fun stop(context: Context) {
            try {
                context.stopService(Intent(context, KeepAliveService::class.java))
            } catch (e: Exception) {
                Log.w(TAG, "Could not stop keep-alive service: ${e.message}")
            }
        }
    }
}
