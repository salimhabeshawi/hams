// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

import android.content.Context
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.audiofx.NoiseSuppressor

data class AllowedHeadphone(val id: Int, val type: Int)

class AudioRoute(private val context: Context) {
    private val audioManager = context.getSystemService(AudioManager::class.java)
    private val callback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) = notifyRoute()
        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) = notifyRoute()
    }
    private var listener: ((AllowedHeadphone?) -> Unit)? = null

    fun start(onChanged: (AllowedHeadphone?) -> Unit) {
        listener = onChanged
        audioManager.registerAudioDeviceCallback(callback, null)
        notifyRoute()
    }

    fun stop() {
        audioManager.unregisterAudioDeviceCallback(callback)
        listener = null
    }

    fun current(): AllowedHeadphone? = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        .asSequence()
        .filter { it.isAllowedHeadphone() }
        .sortedBy { it.priority() }
        .firstOrNull()
        ?.let { AllowedHeadphone(it.id, it.type) }

    fun noiseSuppressor(sessionId: Int): NoiseSuppressor? =
        if (NoiseSuppressor.isAvailable()) NoiseSuppressor.create(sessionId) else null

    private fun notifyRoute() { listener?.invoke(current()) }

    private fun AudioDeviceInfo.isAllowedHeadphone(): Boolean = type in allowedTypes

    private fun AudioDeviceInfo.priority(): Int = when (type) {
        AudioDeviceInfo.TYPE_WIRED_HEADSET, AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> 0
        AudioDeviceInfo.TYPE_USB_HEADSET, AudioDeviceInfo.TYPE_USB_DEVICE -> 1
        AudioDeviceInfo.TYPE_BLE_HEADSET, AudioDeviceInfo.TYPE_HEARING_AID -> 2
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> 3
        AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> 4
        else -> Int.MAX_VALUE
    }

    companion object {
        private val allowedTypes = setOf(
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
            AudioDeviceInfo.TYPE_USB_HEADSET,
            AudioDeviceInfo.TYPE_USB_DEVICE,
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
            AudioDeviceInfo.TYPE_BLE_HEADSET,
            AudioDeviceInfo.TYPE_HEARING_AID,
        )
    }
}
