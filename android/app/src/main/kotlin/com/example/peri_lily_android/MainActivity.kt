package com.example.peri_lily_android

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.perilily/python_stt"
    private var isListening = false

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Initialize Python on the Android device if it isn't already
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }

        // 2. Set up the bridge to listen to Dart
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    isListening = true
                    startPythonVoiceEngine()
                    result.success(null)
                }
                "stopListening" -> {
                    isListening = false
                    // Logic to halt Python script goes here
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startPythonVoiceEngine() {
        val py = Python.getInstance()
        // We will call a python script named 'stt_engine.py'
        val module = py.getModule("stt_engine")

        // Run this in a background thread so we don't freeze the UI
        Thread {
            while (isListening) {
                // Call the python function
                val recognizedText = module.callAttr("listen_for_words").toString()

                if (recognizedText.isNotEmpty()) {
                    // Send the text back to Flutter!
                    runOnUiThread {
                        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL)
                            .invokeMethod("onWordRecognized", mapOf("text" to recognizedText))
                    }
                }
            }
        }.start()
    }
}