package com.vanimitra.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vanimitra.app/screenshot"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "takeScreenshot" -> {
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_TAKE_SCREENSHOT"
                    startService(serviceIntent)
                    result.success(true)
                }
                "typeText" -> {
                    val text = call.argument<String>("text")
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_TYPE_TEXT"
                    serviceIntent.putExtra("text", text)
                    startService(serviceIntent)
                    result.success(true)
                }
                "closeApp" -> {
                    val appName = call.argument<String>("app")
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_CLOSE_APP"
                    serviceIntent.putExtra("appName", appName)
                    startService(serviceIntent)
                    result.success(true)
                }
                "clickIndex" -> {
                    val index = call.argument<Int>("index") ?: 0
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_CLICK_INDEX"
                    serviceIntent.putExtra("index", index)
                    startService(serviceIntent)
                    result.success(true)
                }
                "clickText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_CLICK_TEXT"
                    serviceIntent.putExtra("text", text)
                    startService(serviceIntent)
                    result.success(true)
                }
                "beep" -> {
                    val type = call.argument<String>("type") ?: "start"
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = if (type == "start") "ACTION_BEEP_START" else "ACTION_BEEP_SUCCESS"
                    startService(serviceIntent)
                    result.success(true)
                }
                "goBack" -> {
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_GO_BACK"
                    startService(serviceIntent)
                    result.success(true)
                }
                "goHome" -> {
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_GO_HOME"
                    startService(serviceIntent)
                    result.success(true)
                }
                "lockScreen" -> {
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_LOCK_SCREEN"
                    startService(serviceIntent)
                    result.success(true)
                }
                "toggleWifi" -> {
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_TOGGLE_WIFI"
                    startService(serviceIntent)
                    result.success(true)
                }
                "toggleBluetooth" -> {
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_TOGGLE_BT"
                    startService(serviceIntent)
                    result.success(true)
                }
                "readScreen" -> {
                    val serviceIntent = Intent(this, VanimitraAccessibilityService::class.java)
                    serviceIntent.action = "ACTION_READ_SCREEN"
                    startService(serviceIntent)
                    
                    // Setup a one-time receiver for the result
                    val receiver = object : android.content.BroadcastReceiver() {
                        override fun onReceive(context: android.content.Context?, intent: android.content.Intent?) {
                            val text = intent?.getStringExtra("text") ?: ""
                            result.success(text)
                            unregisterReceiver(this)
                        }
                    }
                    val filter = android.content.IntentFilter("com.vanimitra.app.SCREEN_TEXT")
                    registerReceiver(receiver, filter)
                }
                "relaunchApp" -> {
                    val intent = Intent(this, MainActivity::class.java)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    startActivity(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
