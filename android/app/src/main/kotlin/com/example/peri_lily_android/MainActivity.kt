package com.example.peri_lily_android

import android.os.Bundle
import android.content.Intent
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import android.telephony.SmsManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.perilily/python_stt"
    private val SMS_CHANNEL = "com.perilily/sms"
    private var initialRoute: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent, isNewIntent = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent, isNewIntent = true)
    }

    private fun handleIntent(intent: Intent, isNewIntent: Boolean) {
        if (intent.action == "com.perilily.ACTION_DECOY") {
            initialRoute = "/decoy"
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
            if (isNewIntent) {
                flutterEngine?.navigationChannel?.pushRoute("/decoy")
            }
        } else {

            initialRoute = null
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            ) }
    }

    override fun getInitialRoute(): String? {
        return initialRoute ?: super.getInitialRoute()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(applicationContext))
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "analyzeText") {
                val text = call.argument<String>("text") ?: ""
                val safeWordsJson = call.argument<String>("safeWords") ?: "[]"

                val py = Python.getInstance()
                val module = py.getModule("nlp_engine")
                val isTriggered = module.callAttr("analyze_for_triggers", text, safeWordsJson).toBoolean()

                result.success(isTriggered)
            }
            else if (call.method == "startDecoyService") {
                val serviceIntent = Intent(this, DecoyNotificationService::class.java)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                result.success(true)
            }
            else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendBackgroundSms") {
                val message = call.argument<String>("message") ?: ""
                val recipients = call.argument<List<String>>("recipients") ?: emptyList()

                try {
                    val smsManager = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                        applicationContext.getSystemService(SmsManager::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        SmsManager.getDefault()
                    }

                    for (recipient in recipients) {
                        try {
                            val parts = smsManager.divideMessage(message)
                            if (parts.size > 1) {
                                smsManager.sendMultipartTextMessage(recipient, null, parts, null, null)
                            } else {
                                smsManager.sendTextMessage(recipient, null, message, null, null)
                            }
                        } catch (e: Exception) {
                            // Fallback: truncate and retry
                            val short = message.take(160)
                            smsManager.sendTextMessage(recipient, null, short, null, null)
                        }
                    }
                    result.success("Background SMS sent successfully to ${recipients.size} recipients")
                } catch (e: Exception) {
                    result.error("SMS_FAILED", "Failed to send SMS in background: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}