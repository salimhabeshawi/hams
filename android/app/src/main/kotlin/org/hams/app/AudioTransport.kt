// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetSocketAddress
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class AudioTransport(
    private val socket: DatagramSocket = DatagramSocket(),
    private val packetCodec: (AudioPacket) -> ByteArray,
) : AutoCloseable {
    private val listeners = ConcurrentHashMap<Int, InetSocketAddress>()
    private val scheduler = Executors.newSingleThreadScheduledExecutor()

    init {
        socket.trafficClass = 0xB8
        scheduler.scheduleAtFixedRate({
            listeners.values.forEach { address ->
                val hello = byteArrayOf('H'.code.toByte(), 'M'.code.toByte(), 1, 2)
                socket.send(DatagramPacket(hello, hello.size, address))
            }
        }, 0, 1, TimeUnit.SECONDS)
    }

    fun register(listenerId: Int, address: InetSocketAddress) {
        listeners[listenerId] = address
    }

    fun send(packet: AudioPacket) {
        val address = listeners[packet.listenerId] ?: return
        val bytes = packetCodec(packet)
        socket.send(DatagramPacket(bytes, bytes.size, address))
    }

    override fun close() {
        scheduler.shutdownNow()
        socket.close()
        listeners.clear()
    }
}
