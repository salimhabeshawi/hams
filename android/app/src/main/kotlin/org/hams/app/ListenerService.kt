// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

class ListenerService : SessionForegroundService() {
    override val notificationTitle = "Hams listener"
    override val isSpeaker = false
}
