package io.intheloup.beaconsexample

import android.content.Intent
import io.flutter.app.FlutterApplication
import io.intheloup.beacons.BeaconsPlugin
import io.intheloup.beacons.data.BackgroundMonitoringEvent

class App : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()

        BeaconsPlugin.init(this)
    }
}