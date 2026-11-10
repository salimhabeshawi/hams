// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PackageUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            context.stopService(Intent(context, SpeakerService::class.java))
            context.stopService(Intent(context, ListenerService::class.java))
        }
    }
}
