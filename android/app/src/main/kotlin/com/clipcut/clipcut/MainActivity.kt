package com.clipcut.clipcut

import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.clipcut/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        scanMediaFile(path) { success ->
                            result.success(success)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun scanMediaFile(path: String, callback: (Boolean) -> Unit) {
        val file = File(path)
        if (!file.exists()) {
            callback(false)
            return
        }

        MediaScannerConnection.scanFile(
            this,
            arrayOf(path),
            arrayOf("video/mp4")
        ) { _, _ ->
            runOnUiThread {
                callback(true)
            }
        }
    }
}
