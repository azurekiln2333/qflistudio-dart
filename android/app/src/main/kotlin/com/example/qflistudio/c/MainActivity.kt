package com.azurekiln.qfli.dartwing

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val sdkExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val sdk = DartSdkRuntime(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "qfli_dartwing/sdk")
            .setMethodCallHandler { call, result ->
                if (call.method != "prepare") {
                    result.notImplemented()
                } else {
                    sdkExecutor.execute {
                        try {
                            val layout = sdk.prepare()
                            runOnUiThread { result.success(layout) }
                        } catch (error: Exception) {
                            runOnUiThread { result.error("DART_SDK_PREPARE_FAILED", error.message, null) }
                        }
                    }
                }
            }
    }

    override fun onDestroy() {
        sdkExecutor.shutdown()
        super.onDestroy()
    }
}
