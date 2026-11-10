// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

import android.util.Base64
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.EOFException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.Inet4Address
import java.net.InetAddress
import java.net.NetworkInterface
import java.net.ServerSocket
import java.net.Socket
import java.nio.ByteBuffer
import java.nio.charset.StandardCharsets
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.MessageDigest
import java.security.PrivateKey
import java.security.PublicKey
import java.security.SecureRandom
import java.security.SignatureException
import java.security.spec.ECGenParameterSpec
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.X509EncodedKeySpec
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit
import javax.crypto.Cipher
import javax.crypto.KeyAgreement
import javax.crypto.Mac
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/** Network information deliberately excludes interface and hardware names. */
data class SafeInterface(val address: String, val prefixLength: Short, val loopback: Boolean)

object IdentitySafeNetwork {
    fun interfaces(): List<SafeInterface> = NetworkInterface.getNetworkInterfaces()
        ?.asSequence()
        ?.flatMap { ni -> ni.interfaceAddresses.asSequence() }
        ?.mapNotNull { address ->
            val inet = address.address
            if (inet is Inet4Address) SafeInterface(
                inet.hostAddress, address.networkPrefixLength, inet.isLoopbackAddress
            ) else null
        }
        ?.distinctBy { it.address }
        ?.toList()
        ?: emptyList()

    fun localAddresses(): List<String> = interfaces().map { it.address }
}

enum class DiscoveryMethod { MULTICAST, BROADCAST, GATEWAY, MANUAL }
data class DiscoveryTarget(val method: DiscoveryMethod, val address: InetAddress, val port: Int = 41710)
data class Announcement(
    val sessionId: String, val deviceId: String, val name: String, val title: String?,
    val pin: Boolean, val listeners: Int, val tcp: Int, val udp: Int, val state: String
) {
    fun json(): Map<String, Any?> = mapOf(
        "app" to "hams", "v" to 1, "sessionId" to sessionId, "deviceId" to deviceId,
        "name" to name, "title" to title, "pin" to pin, "listeners" to listeners,
        "max" to 50, "tcp" to tcp, "udp" to udp, "state" to state
    )
}

/** Creates all local-only discovery destinations; callers may run them concurrently. */
object DiscoveryPlanner {
    const val DISCOVERY_PORT = 41710
    const val MULTICAST = "239.255.42.99"
    fun targets(gateway: String? = null, manual: String? = null): List<DiscoveryTarget> {
        val result = mutableListOf(DiscoveryTarget(DiscoveryMethod.MULTICAST,
            InetAddress.getByName(MULTICAST)))
        IdentitySafeNetwork.interfaces().filterNot { it.loopback }.forEach {
            val parts = it.address.split('.')
            if (parts.size == 4) result += DiscoveryTarget(DiscoveryMethod.BROADCAST,
                InetAddress.getByName("${parts[0]}.${parts[1]}.${parts[2]}.255"))
        }
        gateway?.let { result += DiscoveryTarget(DiscoveryMethod.GATEWAY, InetAddress.getByName(it)) }
        manual?.let {
            val split = it.trim().split(':')
            require(split.size == 1 || split.size == 2)
            result += DiscoveryTarget(DiscoveryMethod.MANUAL, InetAddress.getByName(split[0]),
                split.getOrNull(1)?.toIntOrNull() ?: 41711)
        }
        return result.distinctBy { "${it.method}:${it.address.hostAddress}:${it.port}" }
    }
}

class DiscoveryProbe(private val socket: DatagramSocket = DatagramSocket()) : AutoCloseable {
    fun sendWho(target: DiscoveryTarget, deviceId: String) {
        val body = Json.encode(mapOf("app" to "hams", "v" to 1, "type" to "WHO", "deviceId" to deviceId))
        socket.send(DatagramPacket(body, body.size, target.address, target.port))
    }
    fun receive(timeoutMs: Int = 500): Map<String, Any?>? {
        socket.soTimeout = timeoutMs
        val bytes = ByteArray(4096); return try {
            val packet = DatagramPacket(bytes, bytes.size); socket.receive(packet)
            Json.decode(packet.data.copyOf(packet.length))
        } catch (_: java.net.SocketTimeoutException) { null }
    }
    override fun close() { socket.close() }
}

class SessionKeys(private val random: SecureRandom = SecureRandom()) {
    var epoch: Int = 0; private set
    var key: ByteArray = ByteArray(16).also(random::nextBytes); private set
    fun rekey(): ByteArray { epoch = (epoch + 1) and 0xff; key = ByteArray(16).also(random::nextBytes); return key.copyOf() }
}

object Json {
    fun encode(values: Map<String, Any?>): ByteArray =
        encodeValue(values).toByteArray(StandardCharsets.UTF_8)

    fun decode(bytes: ByteArray): Map<String, Any?> {
        val parser = Parser(String(bytes, StandardCharsets.UTF_8))
        return parser.objectValue()
    }

    private fun encodeValue(v: Any?): String = when (v) {
        null -> "null"
        is String -> "\"" + v.replace("\\", "\\\\").replace("\"", "\\\"")
            .replace("\n", "\\n").replace("\r", "\\r") + "\""
        is Number, is Boolean -> v.toString()
        is Map<*, *> -> v.entries.joinToString(prefix = "{", postfix = "}") {
            encodeValue(it.key.toString()) + ":" + encodeValue(it.value)
        }
        is Iterable<*> -> v.joinToString(prefix = "[", postfix = "]", transform = ::encodeValue)
        else -> encodeValue(v.toString())
    }

    private class Parser(private val text: String) {
        private var i = 0
        fun objectValue(): Map<String, Any?> {
            skip('{'); val result = linkedMapOf<String, Any?>()
            skipWhitespace()
            while (peek() != '}') {
                val key = string(); skip(':'); result[key] = value(); skipWhitespace()
                if (peek() == ',') { i++; skipWhitespace() } else break
            }
            skip('}'); return result
        }
        private fun value(): Any? {
            skipWhitespace()
            return when (peek()) {
                '"' -> string()
                '{' -> objectValue()
                't' -> { i += 4; true }
                'f' -> { i += 5; false }
                'n' -> { i += 4; null }
                else -> number()
            }
        }
        private fun number(): Number {
            val start = i
            while (i < text.length && "-+.0123456789eE".contains(text[i])) i++
            val s = text.substring(start, i)
            return if (s.contains('.') || s.contains('e', true)) s.toDouble() else s.toLong()
        }
        private fun string(): String {
            skip('"'); val out = StringBuilder()
            while (i < text.length && text[i] != '"') {
                if (text[i] == '\\') { i++; out.append(when (text[i++]) {
                    'n' -> '\n'; 'r' -> '\r'; 't' -> '\t'; '"' -> '"'; '\\' -> '\\'
                    else -> text[i - 1]
                }) } else out.append(text[i++])
            }
            skip('"'); return out.toString()
        }
        private fun skip(c: Char) { skipWhitespace(); require(i < text.length && text[i++] == c) }
        private fun skipWhitespace() { while (i < text.length && text[i].isWhitespace()) i++ }
        private fun peek(): Char { skipWhitespace(); return text.getOrElse(i) { '}' } }
    }
}

class LengthPrefixedJsonCodec(private val maxBytes: Int = 1 shl 20) {
    fun write(output: DataOutputStream, message: Map<String, Any?>) {
        val body = Json.encode(message)
        require(body.isNotEmpty() && body.size <= maxBytes)
        output.writeInt(body.size); output.write(body); output.flush()
    }
    fun read(input: DataInputStream): Map<String, Any?> {
        val length = try { input.readInt() } catch (_: EOFException) { return emptyMap() }
        require(length in 1..maxBytes) { "invalid frame length" }
        val body = ByteArray(length); input.readFully(body)
        return Json.decode(body)
    }
    fun frame(message: Map<String, Any?>): ByteArray {
        val body = Json.encode(message)
        require(body.size in 1..maxBytes)
        return ByteBuffer.allocate(4 + body.size).putInt(body.size).put(body).array()
    }
}

object HamsCrypto {
    private val random = SecureRandom()
    fun newKeyPair(): KeyPair = KeyPairGenerator.getInstance("EC").apply {
        initialize(ECGenParameterSpec("secp256r1"), random)
    }.generateKeyPair()

    fun publicKey(keyPair: KeyPair): String = Base64.encodeToString(keyPair.public.encoded, Base64.NO_WRAP)
    fun decodePublic(encoded: String): PublicKey = KeyFactory.getInstance("EC")
        .generatePublic(X509EncodedKeySpec(Base64.decode(encoded, Base64.DEFAULT)))
    fun decodePrivate(encoded: String): PrivateKey = KeyFactory.getInstance("EC")
        .generatePrivate(PKCS8EncodedKeySpec(Base64.decode(encoded, Base64.DEFAULT)))

    fun sharedSecret(privateKey: PrivateKey, publicKey: PublicKey): ByteArray =
        KeyAgreement.getInstance("ECDH").apply {
            init(privateKey); doPhase(publicKey, true)
        }.generateSecret()

    fun hkdfSha256(ikm: ByteArray, salt: ByteArray = ByteArray(32), info: ByteArray = ByteArray(0), length: Int): ByteArray {
        val actualSalt = if (salt.isEmpty()) ByteArray(32) else salt
        val extract = Mac.getInstance("HmacSHA256").apply { init(SecretKeySpec(actualSalt, "HmacSHA256")) }
            .doFinal(ikm)
        val out = ByteArray(length); var previous = ByteArray(0); var offset = 0; var counter = 1
        while (offset < length) {
            previous = Mac.getInstance("HmacSHA256").apply { init(SecretKeySpec(extract, "HmacSHA256")) }
                .doFinal(previous + info + counter.toByte())
            val count = minOf(previous.size, length - offset)
            previous.copyInto(out, offset, 0, count); offset += count; counter++
        }
        return out
    }

    fun wrap(key: ByteArray, plaintext: ByteArray, aad: ByteArray = ByteArray(0)): ByteArray {
        val nonce = ByteArray(12).also(random::nextBytes)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key.copyOf(16), "AES"), GCMParameterSpec(128, nonce))
        cipher.updateAAD(aad)
        return nonce + cipher.doFinal(plaintext)
    }
    fun unwrap(key: ByteArray, wrapped: ByteArray, aad: ByteArray = ByteArray(0)): ByteArray {
        require(wrapped.size >= 28)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key.copyOf(16), "AES"),
            GCMParameterSpec(128, wrapped.copyOfRange(0, 12)))
        cipher.updateAAD(aad); return cipher.doFinal(wrapped.copyOfRange(12, wrapped.size))
    }
    fun nonce(salt: Int, epoch: Int, sequence: Long): ByteArray =
        ByteBuffer.allocate(12).putInt(salt).put(epoch.toByte()).put(ByteArray(3))
            .putInt(sequence.toInt()).array()
    fun pinProof(sharedSecret: ByteArray, pin: String): ByteArray =
        Mac.getInstance("HmacSHA256").apply { init(SecretKeySpec(sharedSecret, "HmacSHA256")) }
            .doFinal(("hams-pin$pin").toByteArray(StandardCharsets.UTF_8))
}

enum class AdmissionDecision { PENDING, ACCEPT, DECLINE, BLOCK, FULL, WRONG_PIN, LOCKED }
data class AdmissionResult(val decision: AdmissionDecision, val retryAfterSec: Int = 0)

class AdmissionController(private val clockMs: () -> Long = { System.currentTimeMillis() }) {
    companion object { const val MAX_LISTENERS = 50 }
    private val trusted = ConcurrentHashMap.newKeySet<String>()
    private val admitted = ConcurrentHashMap.newKeySet<String>()
    private val declinedUntil = ConcurrentHashMap<String, Long>()
    private val removedUntil = ConcurrentHashMap<String, Long>()
    private val blocked = ConcurrentHashMap.newKeySet<String>()
    private val pinFailures = ConcurrentHashMap<String, Int>()
    private val pinLockedUntil = ConcurrentHashMap<String, Long>()
    var autoAccept = false
    fun trust(id: String) { trusted += id }
    fun untrust(id: String) { trusted -= id }
    fun isTrusted(id: String) = trusted.contains(id)
    fun decide(id: String, pinCorrect: Boolean, accept: Boolean = true): AdmissionResult {
        val now = clockMs()
        if (blocked.contains(id)) return AdmissionResult(AdmissionDecision.BLOCK)
        pinLockedUntil[id]?.let { if (it > now) return AdmissionResult(AdmissionDecision.LOCKED, ((it - now) / 1000).toInt()) }
        declinedUntil[id]?.let { if (it > now) return AdmissionResult(AdmissionDecision.DECLINE, ((it - now) / 1000).toInt()) }
        removedUntil[id]?.let { if (it > now) return AdmissionResult(AdmissionDecision.DECLINE, ((it - now) / 1000).toInt()) }
        if (!pinCorrect) {
            val failures = (pinFailures[id] ?: 0) + 1; pinFailures[id] = failures
            if (failures >= 5) { pinFailures.remove(id); pinLockedUntil[id] = now + 60_000; return AdmissionResult(AdmissionDecision.LOCKED, 60) }
            return AdmissionResult(AdmissionDecision.WRONG_PIN, 0)
        }
        pinFailures.remove(id)
        if (admitted.size >= MAX_LISTENERS && !admitted.contains(id)) return AdmissionResult(AdmissionDecision.FULL)
        if (accept && (autoAccept || trusted.contains(id))) { admitted += id; return AdmissionResult(AdmissionDecision.ACCEPT) }
        if (!accept) { declinedUntil[id] = now + 60_000; return AdmissionResult(AdmissionDecision.DECLINE, 60) }
        return AdmissionResult(AdmissionDecision.PENDING)
    }
    fun remove(id: String) { admitted -= id; removedUntil[id] = clockMs() + 300_000 }
    fun block(id: String) { admitted -= id; blocked += id }
    fun admit(id: String) { if (admitted.size < MAX_LISTENERS) admitted += id }
    fun count() = admitted.size
}

class ReconnectBackoff {
    private var attempt = 0
    fun reset() { attempt = 0 }
    fun nextDelaySeconds(): Int = if (attempt++ < 3) attempt else 5
    fun attempts() = attempt
}

enum class ControlState { IDLE, CONNECTING, PENDING, CONNECTED, RECONNECTING, ENDED, KICKED, BLOCKED }
class ControlStateMachine {
    var state = ControlState.IDLE; private set
    fun connect() { if (state == ControlState.IDLE || state == ControlState.RECONNECTING) state = ControlState.CONNECTING }
    fun pending() { if (state == ControlState.CONNECTING) state = ControlState.PENDING }
    fun accepted() { if (state == ControlState.PENDING) state = ControlState.CONNECTED }
    fun dropped() { if (state == ControlState.CONNECTED) state = ControlState.RECONNECTING }
    fun ended() { state = ControlState.ENDED }
    fun kicked() { state = ControlState.KICKED }
    fun blocked() { state = ControlState.BLOCKED }
}

class Heartbeat(private val timeoutMs: Long = 7_000, private val now: () -> Long = { System.currentTimeMillis() }) {
    private var last = now()
    fun received() { last = now() }
    fun isAlive() = now() - last <= timeoutMs
}

/** A minimal TCP loopback server/client used by diagnostics and tests. */
class LoopbackControlPlane(private val codec: LengthPrefixedJsonCodec = LengthPrefixedJsonCodec()) {
    fun roundTrip(message: Map<String, Any?>): Map<String, Any?> {
        ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { server ->
            val thread = Thread {
                server.accept().use { socket ->
                    val input = DataInputStream(socket.getInputStream()); val output = DataOutputStream(socket.getOutputStream())
                    codec.write(output, codec.read(input))
                }
            }.also { it.start() }
            Socket(InetAddress.getLoopbackAddress(), server.localPort).use { socket ->
                val input = DataInputStream(socket.getInputStream()); val output = DataOutputStream(socket.getOutputStream())
                codec.write(output, message); return codec.read(input)
            }.also { thread.join(2_000) }
        }
    }
}
