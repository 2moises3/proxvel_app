package com.proxvel.proxvell_app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class UpdateCheckWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        var connection: HttpURLConnection? = null
        return try {
            val response = (URL("https://proxback-production.up.railway.app/api/v1/releases/latest?platform=android")
                .openConnection() as HttpURLConnection).apply {
                connectTimeout = 10000
                readTimeout = 10000
                requestMethod = "GET"
            }
            connection = response
            if (response.responseCode != 200) return Result.retry()
            val release = JSONObject(response.inputStream.bufferedReader().use { it.readText() })
                .optJSONObject("data") ?: return Result.success()
            val code = release.optInt("version_code", 0)
            val installed = if (Build.VERSION.SDK_INT >= 28) {
                applicationContext.packageManager.getPackageInfo(applicationContext.packageName, 0).longVersionCode
            } else {
                @Suppress("DEPRECATION")
                applicationContext.packageManager.getPackageInfo(applicationContext.packageName, 0).versionCode.toLong()
            }
            if (code <= installed) return Result.success()
            val preferences = applicationContext.getSharedPreferences("proxvel_updates", Context.MODE_PRIVATE)
            if (preferences.getInt("notified_code", 0) >= code) return Result.success()
            if (Build.VERSION.SDK_INT >= 33 && applicationContext.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return Result.success()
            val manager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channelId = "proxvel_updates"
            manager.createNotificationChannel(NotificationChannel(channelId, "Actualizaciones de PROXVEL", NotificationManager.IMPORTANCE_DEFAULT))
            val intent = Intent(applicationContext, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(applicationContext, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val version = release.optString("version_name")
            val notification = NotificationCompat.Builder(applicationContext, channelId)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("PROXVEL $version disponible")
                .setContentText("Abre la app para ver los cambios y actualizar.")
                .setContentIntent(pending)
                .setAutoCancel(true)
                .build()
            manager.notify(1001, notification)
            preferences.edit().putInt("notified_code", code).apply()
            Result.success()
        } catch (_: Exception) {
            Result.retry()
        } finally {
            connection?.disconnect()
        }
    }
}
