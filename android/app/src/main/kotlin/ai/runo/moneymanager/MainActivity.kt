package ai.runo.moneymanager

import ai.runo.moneymanager.handlers.TelephonyHandler
import ai.runo.moneymanager.pigeon.TelephonyApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val binaryMessenger = flutterEngine.dartExecutor.binaryMessenger

        // Register Channels
        TelephonyApi.setUp(binaryMessenger, TelephonyHandler(applicationContext))
    }

}

