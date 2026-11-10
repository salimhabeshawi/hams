// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

data class AudioPacket(
    val listenerId: Int,
    val epoch: Int,
    val sequence: Long,
    val timestampMs: Long,
    val payload: ByteArray,
)

/** The UDP header is authenticated as GCM AAD and is never encrypted. */
object AudioPacketCodec {
    private const val MAGIC_0: Byte = 'H'.code.toByte()
    private const val MAGIC_1: Byte = 'M'.code.toByte()
    private const val VERSION: Byte = 1
    private const val AUDIO: Byte = 1
    const val HEADER_SIZE = 15
    private const val TAG_SIZE = 16

    fun encode(packet: AudioPacket, key: ByteArray, salt: ByteArray): ByteArray {
        require(key.size == 16 && salt.size == 4)
        val header = header(packet)
        val encrypted = cipher(Cipher.ENCRYPT_MODE, key, nonce(packet.epoch, packet.sequence, salt), header)
            .doFinal(packet.payload)
        return header + encrypted
    }

    fun decode(bytes: ByteArray, key: ByteArray, salt: ByteArray): AudioPacket {
        require(bytes.size >= HEADER_SIZE + TAG_SIZE)
        require(bytes[0] == MAGIC_0 && bytes[1] == MAGIC_1 && bytes[2] == VERSION && bytes[3] == AUDIO)
        val header = bytes.copyOfRange(0, HEADER_SIZE)
        val view = ByteBuffer.wrap(header).order(ByteOrder.BIG_ENDIAN)
        view.position(4)
        val packet = AudioPacket(
            view.short.toInt() and 0xffff,
            view.get().toInt() and 0xff,
            view.int.toLong() and 0xffffffffL,
            view.int.toLong() and 0xffffffffL,
            ByteArray(0),
        )
        val plain = cipher(Cipher.DECRYPT_MODE, key, nonce(packet.epoch, packet.sequence, salt), header)
            .doFinal(bytes, HEADER_SIZE, bytes.size - HEADER_SIZE)
        return packet.copy(payload = plain)
    }

    private fun header(packet: AudioPacket): ByteArray = ByteBuffer.allocate(HEADER_SIZE)
        .order(ByteOrder.BIG_ENDIAN)
        .put(MAGIC_0).put(MAGIC_1).put(VERSION).put(AUDIO)
        .putShort(packet.listenerId.toShort()).put(packet.epoch.toByte())
        .putInt(packet.sequence.toInt()).putInt(packet.timestampMs.toInt()).array()

    private fun nonce(epoch: Int, sequence: Long, salt: ByteArray): ByteArray =
        salt + byteArrayOf(epoch.toByte(), 0, 0, 0) +
            ByteBuffer.allocate(4).order(ByteOrder.BIG_ENDIAN).putInt(sequence.toInt()).array()

    private fun cipher(mode: Int, key: ByteArray, nonce: ByteArray, aad: ByteArray): Cipher =
        Cipher.getInstance("AES/GCM/NoPadding").also {
            it.init(mode, SecretKeySpec(key, "AES"), GCMParameterSpec(128, nonce))
            it.updateAAD(aad)
        }
}

class AdaptiveJitterBuffer(private val capacity: Int = 8) {
    private val frames = java.util.TreeMap<Long, ByteArray>()
    private var nextSequence: Long? = null
    private var started = false
    init { require(capacity in 2..8) }

    fun offer(sequence: Long, payload: ByteArray) {
        if (started && nextSequence != null && sequence < nextSequence!!) return
        if (frames.size >= capacity && !frames.containsKey(sequence)) frames.pollFirstEntry()
        frames.putIfAbsent(sequence, payload)
        if (nextSequence == null || (!started && sequence < nextSequence!!)) {
            nextSequence = frames.firstKey()
        }
    }

    fun poll(): ByteArray? {
        val expected = nextSequence ?: return null
        started = true
        val frame = frames.remove(expected)
        if (frame != null) {
            nextSequence = expected + 1
            return frame
        }
        if (frames.isEmpty()) {
            nextSequence = null
            return null
        }
        nextSequence = frames.firstKey()
        return null
    }

    fun size(): Int = frames.size
    fun reset() { frames.clear(); nextSequence = null; started = false }
}

class DspProcessor {
    var boost = 2.0f
        set(value) { field = value.coerceIn(1f, 4f) }
    private var gain = 1f
    private var previousInput = 0f
    private var previousOutput = 0f

    fun process(samples: FloatArray, sampleRate: Int = 48_000): FloatArray {
        if (samples.isEmpty()) return samples
        var sum = 0.0
        for (sample in samples) sum += sample.toDouble() * sample
        val rms = sqrt(sum / samples.size).toFloat()
        if (rms >= 0.001778f) {
            val target = (0.1259f / max(rms, 1e-6f)).coerceIn(1f, 15.85f)
            val coefficient = if (target < gain) expStep(50, sampleRate) else expStep(800, sampleRate)
            gain += (target - gain) * coefficient
        } else {
            previousInput = 0f
            previousOutput = 0f
        }
        val output = FloatArray(samples.size)
        for (i in samples.indices) {
            val input = samples[i]
            val dcBlocked = input - previousInput + 0.995f * previousOutput
            previousInput = input
            previousOutput = dcBlocked
            val boosted = dcBlocked * gain * boost
            output[i] = softLimit(boosted, 0.89125f)
        }
        return output
    }

    private fun expStep(milliseconds: Int, sampleRate: Int): Float =
        (1f - kotlin.math.exp(-1f / (milliseconds * sampleRate / 1000f))).coerceIn(0.00001f, 1f)

    private fun softLimit(value: Float, ceiling: Float): Float {
        if (abs(value) <= ceiling) return value
        return ceiling * kotlin.math.tanh(value / ceiling)
    }
}

fun randomAudioSalt(random: SecureRandom = SecureRandom()): ByteArray =
    ByteArray(4).also(random::nextBytes)
