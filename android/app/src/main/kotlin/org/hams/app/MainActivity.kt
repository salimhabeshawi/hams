package org.hams.app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    companion object {
        init {
            System.loadLibrary("hams_native")
        }
    }

    private external fun nativeHello(): String

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EngineApi.setUp(flutterEngine.dartExecutor.binaryMessenger, object : EngineApi {
            override fun ping(request: PingRequest): PingReply =
                PingReply(value = nativeHello(), version = version())

            override fun version(): String = "1.0.0"
        })
    }
}
