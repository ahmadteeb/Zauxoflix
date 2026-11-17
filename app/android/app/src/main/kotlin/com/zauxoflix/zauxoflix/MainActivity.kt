package com.zauxoflix.zauxoflix

import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zauxoflix/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTv" -> result.success(isTvDevice())
                    else -> result.notImplemented()
                }
            }
    }

    private fun isTvDevice(): Boolean {
        if (packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
            packageManager.hasSystemFeature("android.hardware.type.television") ||
            packageManager.hasSystemFeature("amazon.hardware.fire_tv")) return true
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        return uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
    }
}
