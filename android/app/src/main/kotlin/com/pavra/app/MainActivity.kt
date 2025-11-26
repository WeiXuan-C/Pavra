package com.pavra.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        // Notification channels are only required for Android O (API 26) and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // Alert Channel - High priority for critical alerts
            val alertChannel = NotificationChannel(
                "alert",
                "Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Critical alerts and urgent notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }

            // Warning Channel - Default priority for warnings
            val warningChannel = NotificationChannel(
                "warning",
                "Warnings",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Warning notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }

            // Info Channel - Low priority for informational messages
            val infoChannel = NotificationChannel(
                "info",
                "Information",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Informational notifications"
                enableLights(false)
                enableVibration(false)
                setShowBadge(true)
            }

            // Success Channel - Default priority for success messages
            val successChannel = NotificationChannel(
                "success",
                "Success",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Success notifications"
                enableLights(true)
                enableVibration(false)
                setShowBadge(true)
            }

            // Register all channels with the system
            notificationManager.createNotificationChannel(alertChannel)
            notificationManager.createNotificationChannel(warningChannel)
            notificationManager.createNotificationChannel(infoChannel)
            notificationManager.createNotificationChannel(successChannel)
        }
    }
}
