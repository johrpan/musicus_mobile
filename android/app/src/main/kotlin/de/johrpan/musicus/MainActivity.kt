package de.johrpan.musicus

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val CHANNEL = "de.johrpan.musicus/platform"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getStorageRoots") {
                result.success(getStorageRoots())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getStorageRoots(): ArrayList<String> {
        val result = ArrayList<String>()

        ContextCompat.getExternalFilesDirs(this, null).forEach {
            val path = it.absolutePath;
            val index = path.lastIndexOf("/Android/data/")

            if (index > 0) {
                result.add(path.substring(0, index))
            }
        }

        return result
    }
}
