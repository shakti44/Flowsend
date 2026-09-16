package com.flowsend.flowsend

import android.content.Intent
import android.webkit.MimeTypeMap
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flowsend/device")
			.setMethodCallHandler { call, result ->
				if (call.method == "deviceName") {
					val manufacturer = Build.MANUFACTURER.trim()
					val model = Build.MODEL.trim()
					result.success(listOf(manufacturer, model)
						.filter { it.isNotEmpty() }
						.joinToString(" "))
				} else if (call.method == "openFile") {
					val path = call.argument<String>("path")
					if (path == null) {
						result.error("INVALID_PATH", "File path is required", null)
						return@setMethodCallHandler
					}
					try {
						val file = File(path)
						val extension = file.extension.lowercase()
						val mimeType = MimeTypeMap.getSingleton()
							.getMimeTypeFromExtension(extension) ?: "application/octet-stream"
						val uri = FileProvider.getUriForFile(
							this,
							"$packageName.fileprovider",
							file,
						)
						startActivity(Intent(Intent.ACTION_VIEW).apply {
							setDataAndType(uri, mimeType)
							addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
							clipData = android.content.ClipData.newRawUri("FlowSend file", uri)
						})
						result.success(null)
					} catch (error: Exception) {
						result.error("OPEN_FAILED", error.message, null)
					}
				} else {
					result.notImplemented()
				}
			}
	}
}
