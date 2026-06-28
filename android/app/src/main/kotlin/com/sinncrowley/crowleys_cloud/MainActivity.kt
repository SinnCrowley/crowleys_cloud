package com.sinncrowley.crowleys_cloud

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings
import android.os.Build

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.sinncrowley.crowleys_cloud/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getDeviceName") {
                var deviceName: String? = null
                
                // 1. Try Settings.Global.device_name
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                        deviceName = Settings.Global.getString(contentResolver, "device_name")
                    }
                } catch (e: Exception) {
                    // Ignore and try fallback
                }

                // 2. Try Settings.Secure.bluetooth_name
                if (deviceName.isNullOrBlank()) {
                    try {
                        deviceName = Settings.Secure.getString(contentResolver, "bluetooth_name")
                    } catch (e: Exception) {
                        // Ignore and try fallback
                    }
                }

                // 3. Try Settings.System.device_name
                if (deviceName.isNullOrBlank()) {
                    try {
                        deviceName = Settings.System.getString(contentResolver, "device_name")
                    } catch (e: Exception) {
                        // Ignore
                    }
                }

                result.success(deviceName)
            } else {
                result.notImplemented()
            }
        }
    }
}

