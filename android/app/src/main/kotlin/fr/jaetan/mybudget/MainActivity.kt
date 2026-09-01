package fr.jaetan.mybudget

import fr.jaetan.mybudget.nano.GeminiNanoPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var nano: GeminiNanoPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nano = GeminiNanoPlugin(flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        nano?.dispose()
        nano = null
        super.onDestroy()
    }
}
