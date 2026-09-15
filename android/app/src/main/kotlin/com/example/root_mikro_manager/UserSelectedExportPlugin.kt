package com.example.root_mikro_manager

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class UserSelectedExportPlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "saveDocument") {
            result.notImplemented()
            return
        }
        if (pendingResult != null) {
            result.error("EXPORT_BUSY", "Un choix de fichier est déjà ouvert.", null)
            return
        }
        val name = call.argument<String>("suggestedName")?.takeIf { it.isNotBlank() }
            ?: "RootMikroManager_export"
        val mime = call.argument<String>("mimeType")?.takeIf { it.isNotBlank() }
            ?: "application/octet-stream"
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes == null) {
            result.error("INVALID_EXPORT", "Le contenu à exporter est absent.", null)
            return
        }
        pendingResult = result
        pendingBytes = bytes
        try {
            activity.startActivityForResult(
                Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = mime
                    putExtra(Intent.EXTRA_TITLE, name)
                },
                REQUEST_CREATE_DOCUMENT,
            )
        } catch (error: Exception) {
            finishWithError("PICKER_FAILED", error)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CREATE_DOCUMENT) return false
        val result = pendingResult ?: return true
        val bytes = pendingBytes
        pendingResult = null
        pendingBytes = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return true
        }
        val uri = data.data!!
        try {
            activity.contentResolver.openOutputStream(uri, "w")?.use { stream ->
                stream.write(bytes ?: ByteArray(0))
                stream.flush()
            } ?: throw IllegalStateException("Impossible d'ouvrir le fichier sélectionné.")
            result.success(uri.toString())
        } catch (error: Exception) {
            result.error("WRITE_FAILED", error.message, null)
        }
        return true
    }

    private fun finishWithError(code: String, error: Exception) {
        pendingResult?.error(code, error.message, null)
        pendingResult = null
        pendingBytes = null
    }

    companion object {
        private const val CHANNEL = "root_mikro_manager/export"
        private const val REQUEST_CREATE_DOCUMENT = 42173
    }
}
