// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

class SpeakerService : SessionForegroundService() {
    override val notificationTitle = "Hams speaker"
    override val isSpeaker = true
}
