package com.henry.flutter_mvvm_riverpod

import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class SosTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            label = "Emergency SOS"
            contentDescription = "Open GoBuddy emergency SOS confirmation"
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        unlockAndRun { openSosConfirmation() }
    }

    private fun openSosConfirmation() {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(SOS_URL), this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pendingIntent = PendingIntent.getActivity(
                this,
                911,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private companion object {
        const val SOS_URL = "gobuddy://app/safety/sos/confirm"
    }
}
