// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

private const val CHANNEL_ID = "hams-session"
private const val ACTION_MUTE = "org.hams.app.action.MUTE"
private const val ACTION_END = "org.hams.app.action.END"
private const val ACTION_DISCONNECT = "org.hams.app.action.DISCONNECT"

abstract class SessionForegroundService : Service() {
    private lateinit var wifiLock: WifiManager.WifiLock
    private var multicastLock: WifiManager.MulticastLock? = null
    private var wakeLock: android.os.PowerManager.WakeLock? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var audioManager: AudioManager? = null

    abstract val notificationTitle: String
    abstract val isSpeaker: Boolean

    override fun onCreate() {
        super.onCreate()
        activeService = this
        createChannel()
        val power = getSystemService(android.os.PowerManager::class.java)
        wakeLock = power.newWakeLock(android.os.PowerManager.PARTIAL_WAKE_LOCK, "hams:session")
            .apply { setReferenceCounted(false); acquire() }
        val wifi = getSystemService(WifiManager::class.java)
        wifiLock = wifi.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "hams:session")
            .apply { setReferenceCounted(false); acquire() }
        audioManager = getSystemService(AudioManager::class.java)
        requestAudioFocus()
        startForeground(NOTIFICATION_ID, notification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_MUTE -> {
                ServiceSessionState.muted = !ServiceSessionState.muted
                SessionRuntimeHolder.mute?.invoke(ServiceSessionState.muted)
            }
            ACTION_END, ACTION_DISCONNECT -> stopSession()
        }
        return START_NOT_STICKY
    }

    fun enableMulticastLock() {
        if (multicastLock == null) {
            multicastLock = getSystemService(WifiManager::class.java)
                .createMulticastLock("hams:discovery")
                .apply { setReferenceCounted(false); acquire() }
        }
    }

    private fun requestAudioFocus() {
        val manager = audioManager ?: return
        val listener = AudioManager.OnAudioFocusChangeListener { change ->
            when {
                change == AudioManager.AUDIOFOCUS_LOSS ||
                    change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                    ServiceSessionState.pausedForFocus = true
                    ServiceSessionState.muted = true
                    SessionRuntimeHolder.mute?.invoke(true)
                }
                change == AudioManager.AUDIOFOCUS_GAIN &&
                    ServiceSessionState.pausedForFocus -> {
                    ServiceSessionState.pausedForFocus = false
                    ServiceSessionState.muted = false
                    SessionRuntimeHolder.mute?.invoke(false)
                }
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest = AudioFocusRequest.Builder(
                if (isSpeaker) AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE
                else AudioManager.AUDIOFOCUS_GAIN
            ).setOnAudioFocusChangeListener(listener).build()
            manager.requestAudioFocus(audioFocusRequest!!)
        } else {
            @Suppress("DEPRECATION")
            manager.requestAudioFocus(
                listener,
                AudioManager.STREAM_MUSIC,
                if (isSpeaker) AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE
                else AudioManager.AUDIOFOCUS_GAIN
            )
        }
    }

    private fun notification(): Notification {
        val open = PendingIntent.getActivity(
            this, 1, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentTitle(notificationTitle)
            .setContentText(if (isSpeaker) "Hams is sharing locally" else "Hams is receiving locally")
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(open)
            .setSilent(true)
        if (isSpeaker) {
            builder.addAction(action(ACTION_MUTE, if (ServiceSessionState.muted) "Unmute" else "Mute"))
                .addAction(action(ACTION_END, "End"))
        } else {
            builder.addAction(action(ACTION_DISCONNECT, "Disconnect"))
        }
        return builder.build()
    }

    private fun action(action: String, title: String): NotificationCompat.Action =
        NotificationCompat.Action.Builder(
            0,
            title,
            PendingIntent.getService(
                this, action.hashCode(), Intent(this, javaClass).setAction(action),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        ).build()

    private fun createChannel() {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "Hams sessions", NotificationManager.IMPORTANCE_LOW)
        )
    }

    private fun stopSession() {
        SessionRuntimeHolder.stop?.invoke()
        ServiceSessionState.clear()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        if (activeService === this) activeService = null
        multicastLock?.let { if (it.isHeld) it.release() }
        if (::wifiLock.isInitialized && wifiLock.isHeld) wifiLock.release()
        wakeLock?.let { if (it.isHeld) it.release() }
        audioFocusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val NOTIFICATION_ID = 41711
        private var activeService: SessionForegroundService? = null
        fun enableMulticast() { activeService?.enableMulticastLock() }
        fun start(context: Context, service: Class<out SessionForegroundService>) {
            val intent = Intent(context, service)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(intent)
            else context.startService(intent)
        }
    }
}

object ServiceSessionState {
    @Volatile var muted = false
    @Volatile var pausedForFocus = false
    fun clear() { muted = false; pausedForFocus = false }
}

object SessionRuntimeHolder {
    var stop: (() -> Unit)? = null
    var mute: ((Boolean) -> Unit)? = null
}
