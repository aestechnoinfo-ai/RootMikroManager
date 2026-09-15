package com.example.root_mikro_manager

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import android.content.Intent

class MainActivity : FlutterActivity() {
    private lateinit var exportPlugin: UserSelectedExportPlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NetworkBindingPlugin(this).register(flutterEngine.dartExecutor.binaryMessenger)
        exportPlugin = UserSelectedExportPlugin(this)
        exportPlugin.register(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (::exportPlugin.isInitialized && exportPlugin.onActivityResult(requestCode, resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }
}
