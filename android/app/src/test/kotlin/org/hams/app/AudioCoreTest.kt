// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

import org.junit.Assert.*
import org.junit.Test
import kotlin.math.sqrt

class AudioCoreTest {
    @Test fun packetCodecAuthenticatesHeaderAndRoundTrips() {
        val packet = AudioPacket(7, 2, 42, 1234, byteArrayOf(1, 2, 3))
        val encoded = AudioPacketCodec.encode(packet, ByteArray(16) { 4 }, byteArrayOf(5, 6, 7, 8))
        val decoded = AudioPacketCodec.decode(encoded, ByteArray(16) { 4 }, byteArrayOf(5, 6, 7, 8))
        assertEquals(packet.listenerId, decoded.listenerId)
        assertEquals(packet.sequence, decoded.sequence)
        assertArrayEquals(packet.payload, decoded.payload)
        encoded[10] = (encoded[10].toInt() xor 1).toByte()
        assertThrows(Exception::class.java) {
            AudioPacketCodec.decode(encoded, ByteArray(16) { 4 }, byteArrayOf(5, 6, 7, 8))
        }
    }

    @Test fun jitterBufferReordersDropsLateAndAdvancesAcrossLoss() {
        val buffer = AdaptiveJitterBuffer()
        buffer.offer(2, byteArrayOf(2)); buffer.offer(1, byteArrayOf(1)); buffer.offer(4, byteArrayOf(4))
        assertArrayEquals(byteArrayOf(1), buffer.poll())
        assertArrayEquals(byteArrayOf(2), buffer.poll())
        assertNull(buffer.poll())
        assertArrayEquals(byteArrayOf(4), buffer.poll())
        buffer.offer(2, byteArrayOf(9)); assertNull(buffer.poll())
    }

    @Test fun dspLevelerAndLimiterStayWithinCeilingAndGateFreezesGain() {
        val dsp = DspProcessor()
        dsp.boost = 4f
        val silence = FloatArray(480) { 0f }
        dsp.process(silence)
        val loud = dsp.process(FloatArray(480) { 1f })
        assertTrue(loud.maxOf { kotlin.math.abs(it) } <= 0.89126f)
        val quiet = dsp.process(FloatArray(480) { 0.0001f })
        assertTrue(quiet.maxOf { kotlin.math.abs(it) } < 0.01f)
    }
}
