// SPDX-License-Identifier: GPL-3.0-or-later
package org.hams.app

import android.app.Service
import android.content.Intent
import android.os.IBinder

class ListenerService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null
}
