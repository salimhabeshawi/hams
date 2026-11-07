// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.util.concurrent.atomic.AtomicLong
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ControlPlaneTest {
    @Test fun codecRoundTripUsesBigEndianLengthPrefix() {
        val codec = LengthPrefixedJsonCodec()
        val bytes = ByteArrayOutputStream()
        codec.write(DataOutputStream(bytes), mapOf("type" to "PING", "n" to 3, "ok" to true))
        val result = codec.read(DataInputStream(ByteArrayInputStream(bytes.toByteArray())))
        assertEquals("PING", result["type"])
        assertEquals(3L, result["n"])
        assertEquals(true, result["ok"])
    }

    @Test fun cryptoRoundTripAndPinProofAreStable() {
        val speaker = HamsCrypto.newKeyPair()
        val listener = HamsCrypto.newKeyPair()
        val a = HamsCrypto.hkdfSha256(HamsCrypto.sharedSecret(speaker.private, listener.public), length = 16)
        val b = HamsCrypto.hkdfSha256(HamsCrypto.sharedSecret(listener.private, speaker.public), length = 16)
        assertArrayEquals(a, b)
        val wrapped = HamsCrypto.wrap(a, "session-key".toByteArray(), "join".toByteArray())
        assertArrayEquals("session-key".toByteArray(), HamsCrypto.unwrap(b, wrapped, "join".toByteArray()))
        assertArrayEquals(HamsCrypto.pinProof(a, "1234"), HamsCrypto.pinProof(b, "1234"))
    }

    @Test fun rekeyProducesDifferentNonceAndKey() {
        val key1 = ByteArray(16) { 1 }; val key2 = ByteArray(16) { 2 }
        assertFalse(HamsCrypto.nonce(1, 1, 1).contentEquals(HamsCrypto.nonce(1, 2, 1)))
        val wrapped = HamsCrypto.wrap(key2, key1)
        assertArrayEquals(key1, HamsCrypto.unwrap(key2, wrapped))
    }

    @Test fun backoffIsOneTwoThreeThenFive() {
        val backoff = ReconnectBackoff()
        assertEquals(1, backoff.nextDelaySeconds()); assertEquals(2, backoff.nextDelaySeconds())
        assertEquals(3, backoff.nextDelaySeconds()); repeat(5) { assertEquals(5, backoff.nextDelaySeconds()) }
        backoff.reset(); assertEquals(1, backoff.nextDelaySeconds())
    }

    @Test fun admissionCooldownsLocksAndBlock() {
        val clock = AtomicLong(0)
        val admission = AdmissionController { clock.get() }
        admission.autoAccept = true
        assertEquals(AdmissionDecision.ACCEPT, admission.decide("a", true).decision)
        admission.remove("a")
        assertEquals(AdmissionDecision.DECLINE, admission.decide("a", true).decision)
        clock.addAndGet(300_001)
        repeat(4) { assertEquals(AdmissionDecision.WRONG_PIN, admission.decide("a", false).decision) }
        assertEquals(AdmissionDecision.LOCKED, admission.decide("a", false).decision)
        admission.block("b"); assertEquals(AdmissionDecision.BLOCK, admission.decide("b", true).decision)
    }

    @Test fun loopbackControlPlaneEchoesFramedJson() {
        val response = LoopbackControlPlane().roundTrip(mapOf("type" to "PING", "value" to "loopback"))
        assertEquals("PING", response["type"]); assertEquals("loopback", response["value"])
    }

    @Test fun stateMachineAndHeartbeat() {
        val state = ControlStateMachine()
        state.connect(); state.pending(); state.accepted(); assertEquals(ControlState.CONNECTED, state.state)
        state.dropped(); assertEquals(ControlState.RECONNECTING, state.state)
        val clock = AtomicLong(0); val heartbeat = Heartbeat(now = { clock.get() })
        heartbeat.received(); clock.set(7_001); assertFalse(heartbeat.isAlive())
    }
}
