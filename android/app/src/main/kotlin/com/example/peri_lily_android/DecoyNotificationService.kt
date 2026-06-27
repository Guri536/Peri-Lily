package com.example.peri_lily_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class DecoyNotificationService : Service() {
    private val CHANNEL_ID = "SystemStatusChannel"

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()

        // 1. Prepare the intent that will launch the Decoy UI
        val tapIntent = Intent(this, MainActivity::class.java).apply {
            action = "com.perilily.ACTION_DECOY"
            putExtra("route", "/decoy")
            this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 2. Build the discreet notification
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("System Status")
            .setContentText("Background sync active.")
            .setSmallIcon(R.mipmap.main_icon)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(pendingIntent, true)
            .setContentIntent(pendingIntent)
            .build()

        // 3. Start the service in the foreground
        startForeground(1, notification)

        // START_STICKY tells Android to restart this service if it gets killed
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "System Background Process",
                NotificationManager.IMPORTANCE_LOW // Lowest importance = no sound/vibration
            ).apply {
                description = "Maintains essential background synchronization."
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}