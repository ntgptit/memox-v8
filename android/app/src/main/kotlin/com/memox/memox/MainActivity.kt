package com.memox.memox

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // FE-B6: screen 24's "Open system settings". The channel's name and
        // method match `plugin_reminder_plugins_data_source.dart`.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "memox/notification_settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "open") result.success(openNotificationSettings())
                else result.notImplemented()
            }
    }

    /** The app's notification settings, or its App info page where a device has none. */
    private fun openNotificationSettings(): Boolean {
        val notifications = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        val appInfo = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", packageName, null))
        for (intent in listOf(notifications, appInfo)) {
            try {
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
                // Falls through to the next page.
            }
        }
        return false
    }
}
