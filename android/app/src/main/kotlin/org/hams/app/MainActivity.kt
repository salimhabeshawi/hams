// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.Settings
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        init { System.loadLibrary("hams_native") }
    }

    private external fun nativeHello(): String
    private external fun nativeStartCapture(deviceId: Int): Boolean
    private external fun nativeAudioSessionId(): Int
    private external fun nativeStopAudio()
    private external fun nativeSetMuted(muted: Boolean)
    private external fun nativeSetBoost(boost: Float)
    private external fun nativeSetNoiseReduction(enabled: Boolean)
    private lateinit var runtime: SessionRuntime

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        runtime = SessionRuntime()
        SessionRuntimeHolder.stop = { runtime.api().stopSession() }
        SessionRuntimeHolder.mute = { runtime.api().setMuted(it) }
        EngineApi.setUp(flutterEngine.dartExecutor.binaryMessenger, runtime.api())
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "hams/events")
            .setStreamHandler(runtime.events)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hams/settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBatteryOptimization" -> {
                        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                        result.success(null)
                    }
                    "setKeepScreenOn" -> {
                        window.addFlags(if (call.argument<Boolean>("enabled") == true)
                            android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON else 0)
                        if (call.argument<Boolean>("enabled") != true) {
                            window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }
                    "setNoiseReduction" -> {
                        runtime.setNoiseReduction(call.argument<Boolean>("enabled") != false)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hams/diagnostics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "report" -> result.success(runtime.report())
                    "setDeveloperTest" -> {
                        runtime.setDeveloperTest(
                            call.argument<Boolean>("loopback") == true,
                            call.argument<Boolean>("tone") == true,
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    private inner class SessionRuntime {
        private val executor = Executors.newCachedThreadPool()
        private var sessionId: String? = null
        private var deviceId: String? = null
        private var name: String? = null
        private var title: String? = null
        private var state = "idle"
        private var pin: String? = null
        private var autoAccept = false
        private var muted = false
        private var boost = 2.0
        private var noiseReductionEnabled = true
        private var developerLoopback = false
        private var developerTone = false
        private val audioRoute = AudioRoute(this@MainActivity)
        private var headphonesConnected = false
        private var noiseSuppressor: android.media.audiofx.NoiseSuppressor? = null
        private val found = linkedMapOf<String, SpeakerAnnouncement>()
        private var tcp: ServerSocket? = null
        private var udp: DatagramSocket? = null
        private val pendingSockets = java.util.concurrent.ConcurrentHashMap<String, Socket>()
        private var eventSink: EventChannel.EventSink? = null
        private val sessionPrefs by lazy {
            getSharedPreferences("hams_session", android.content.Context.MODE_PRIVATE)
        }
        fun report(): Map<String, Any?> = mapOf(
            "state" to state,
            "session" to (sessionId ?: "none"),
            "listenerCount" to 0,
            "maxListeners" to 50,
            "networkReady" to IdentitySafeNetwork.localAddresses().isNotEmpty(),
            "localAddresses" to IdentitySafeNetwork.localAddresses(),
            "headphonesConnected" to headphonesConnected,
            "bufferDepthMs" to 40,
            "estimatedLatencyMs" to 40,
            "packetLossPercent" to 0,
            "jitterMs" to 0,
            "codec" to "Opus 48 kHz mono, 32 kbps constrained VBR",
            "loopback" to developerLoopback,
            "testTone" to developerTone,
        )
        fun setDeveloperTest(loopback: Boolean, tone: Boolean) {
            developerLoopback = loopback
            developerTone = tone
        }
        fun setNoiseReduction(enabled: Boolean) {
            noiseReductionEnabled = enabled
            nativeSetNoiseReduction(enabled)
            noiseSuppressor?.enabled = enabled
        }
        val events = object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { eventSink = events }
            override fun onCancel(arguments: Any?) { eventSink = null }
        }
        private fun emit() {
            eventSink?.success(mapOf(
                "state" to state,
                "sessionId" to sessionId,
                "headphones" to headphonesConnected,
                "level" to 0.0,
            ))
        }

        fun api() = object : EngineApi {
            override fun ping(request: PingRequest) = PingReply(nativeHello(), version())
            override fun version() = "1.0.0"
            override fun snapshot(): EngineSnapshot {
                val persistedState = sessionPrefs.getString("state", null)
                return EngineSnapshot(
                persistedState ?: state,
                sessionId ?: sessionPrefs.getString("sessionId", null),
                title ?: sessionPrefs.getString("title", null),
                name ?: sessionPrefs.getString("name", null), 0L, 50L,
                IdentitySafeNetwork.localAddresses().isNotEmpty(), headphonesConnected, 0.0, null,
                )
            }
            override fun startSpeaker(deviceId: String, name: String, title: String?, pin: String?, autoAccept: Boolean) {
                requestNotificationPermission()
                this@SessionRuntime.deviceId = deviceId
                this@SessionRuntime.name = name
                this@SessionRuntime.title = title
                this@SessionRuntime.pin = pin
                this@SessionRuntime.autoAccept = autoAccept
                SessionForegroundService.start(this@MainActivity, SpeakerService::class.java)
                sessionId = UUID.randomUUID().toString()
                if (!nativeStartCapture(0)) {
                    state = "error"
                    emit()
                    return
                }
                noiseSuppressor = AudioRoute(this@MainActivity).noiseSuppressor(nativeAudioSessionId())?.also {
                    it.enabled = noiseReductionEnabled
                }
                state = "live"
                sessionPrefs.edit().putString("state", state).putString("sessionId", sessionId)
                    .putString("title", title).putString("name", name).apply()
                executor.execute { startServer() }
                emit()
            }
            override fun stopSession() {
                closeSockets()
                noiseSuppressor?.release()
                noiseSuppressor = null
                nativeStopAudio()
                state = "ended"
                sessionPrefs.edit().clear().apply()
                emit()
                stopService(Intent(this@MainActivity, SpeakerService::class.java))
                stopService(Intent(this@MainActivity, ListenerService::class.java))
            }
            override fun discover() {
                SessionForegroundService.enableMulticast()
                executor.execute { probe() }
            }
            override fun speakers() = found.values.toList()
            override fun connect(address: String, port: Long, pin: String?, deviceId: String, name: String) {
                requestNotificationPermission()
                SessionForegroundService.start(this@MainActivity, ListenerService::class.java)
                executor.execute { join(address, port.toInt(), pin, deviceId, name) }
            }

            private fun requestNotificationPermission() {
                if (android.os.Build.VERSION.SDK_INT >= 33 &&
                    checkSelfPermission("android.permission.POST_NOTIFICATIONS") !=
                    android.content.pm.PackageManager.PERMISSION_GRANTED
                ) {
                    requestPermissions(arrayOf("android.permission.POST_NOTIFICATIONS"), 41712)
                }
            }
            override fun cancelConnection() { state = "idle"; emit() }
            override fun respondToRequest(deviceId: String, accept: Boolean, alwaysAllow: Boolean) {
                val socket = pendingSockets.remove(deviceId) ?: return
                executor.execute {
                    socket.use {
                        val codec = LengthPrefixedJsonCodec()
                        codec.write(java.io.DataOutputStream(it.getOutputStream()), mapOf(
                            "type" to if (accept) "JOIN_ACCEPT" else "JOIN_DENY",
                            "reason" to if (accept) null else "declined",
                        ))
                    }
                }
            }
            override fun removeListener(deviceId: String, block: Boolean) {}
            override fun setMuted(muted: Boolean) {
                this@SessionRuntime.muted = muted
                nativeSetMuted(muted)
                state = if (muted) "paused" else "live"
                sessionPrefs.edit().putString("state", state).apply()
                emit()
            }
            override fun setBoost(boost: Double) {
                this@SessionRuntime.boost = boost.coerceIn(1.0, 4.0)
                nativeSetBoost(this@SessionRuntime.boost.toFloat())
            }
        }

        private fun startServer() {
            try {
                tcp = ServerSocket(41711)
                while (!tcp!!.isClosed) {
                    val socket = tcp!!.accept()
                    executor.execute {
                        val codec = LengthPrefixedJsonCodec()
                        val request = codec.read(java.io.DataInputStream(socket.getInputStream().buffered()))
                        val id = request["deviceId"]?.toString() ?: return@execute
                        if (autoAccept) {
                            socket.use {
                                codec.write(java.io.DataOutputStream(it.getOutputStream()), mapOf(
                                    "type" to "JOIN_ACCEPT", "epoch" to 0, "sessionId" to sessionId,
                                ))
                            }
                        } else {
                            pendingSockets[id] = socket
                        }
                    }
                }
            } catch (_: java.io.IOException) {
                // Socket closure is the normal end-of-session path.
            }
        }

        private fun probe() {
            DatagramSocket().use { socket ->
                socket.broadcast = true
                val payload = Json.encode(mapOf("app" to "hams", "v" to 1, "type" to "WHO"))
                DiscoveryPlanner.targets().forEach { target ->
                    socket.send(DatagramPacket(payload, payload.size, target.address, target.port))
                }
                socket.soTimeout = 400
                repeat(4) {
                    try {
                        val buffer = ByteArray(4096)
                        val packet = DatagramPacket(buffer, buffer.size)
                        socket.receive(packet)
                        val message = Json.decode(packet.data.copyOf(packet.length))
                        if (message["type"] == "ANNOUNCE" && message["deviceId"] != deviceId) {
                            val id = message["sessionId"]?.toString() ?: return@repeat
                            found[id] = SpeakerAnnouncement(
                                id, message["deviceId"]?.toString(), message["name"]?.toString(),
                                message["title"]?.toString(), message["pin"] as? Boolean,
                                (message["listeners"] as? Number)?.toLong(), 50L,
                                (message["tcp"] as? Number)?.toLong(), (message["udp"] as? Number)?.toLong(),
                                message["state"]?.toString(), packet.address.hostAddress,
                            )
                        }
                    } catch (_: java.io.IOException) { return@repeat }
                }
            }
        }

        private fun join(address: String, port: Int, pin: String?, deviceId: String, name: String) {
            try {
                java.net.Socket(address, port).use { socket ->
                    val codec = LengthPrefixedJsonCodec()
                    codec.write(java.io.DataOutputStream(socket.getOutputStream()), mapOf(
                        "type" to "JOIN_REQUEST", "deviceId" to deviceId, "name" to name,
                        "pinProof" to pin,
                    ))
                    val response = codec.read(java.io.DataInputStream(socket.getInputStream()))
                    state = if (response["type"] == "JOIN_ACCEPT") "connected" else "pending"
                    emit()
                }
            } catch (_: java.io.IOException) {
                state = "reconnecting"
                emit()
            }
        }

        private fun closeSockets() {
            tcp?.close()
            tcp = null
            udp?.close()
            udp = null
            pendingSockets.values.forEach { it.close() }
            pendingSockets.clear()
        }
        init {
            audioRoute.start {
                headphonesConnected = it != null
                if (state == "connected" && !headphonesConnected) state = "waiting_headphones"
                if (state == "waiting_headphones" && headphonesConnected) state = "connected"
                emit()
            }
        }

        fun close() {
            closeSockets()
            nativeStopAudio()
            noiseSuppressor?.release()
            noiseSuppressor = null
            audioRoute.stop()
            executor.shutdownNow()
        }
    }
}
