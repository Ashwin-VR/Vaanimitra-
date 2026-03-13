package com.vanimitra.app

import com.vanimitra.app.R
import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_TAKE_SCREENSHOT
import android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_RECENTS
import android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME
import android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK
import android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_LOCK_SCREEN
import android.util.Log
import android.media.SoundPool
import android.media.AudioAttributes
import android.view.accessibility.AccessibilityNodeInfo
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.graphics.Path
import android.accessibilityservice.GestureDescription

class VanimitraAccessibilityService : AccessibilityService() {

    companion object {
        const val ACTION_TAKE_SCREENSHOT = "ACTION_TAKE_SCREENSHOT"
        const val ACTION_BEEP_START = "ACTION_BEEP_START"
        const val ACTION_BEEP_SUCCESS = "ACTION_BEEP_SUCCESS"
        const val ACTION_TYPE_TEXT = "ACTION_TYPE_TEXT"
        const val ACTION_CLOSE_APP = "ACTION_CLOSE_APP"
        const val ACTION_CLICK_INDEX = "ACTION_CLICK_INDEX"
        const val ACTION_CLICK_TEXT = "ACTION_CLICK_TEXT"
        const val ACTION_TOGGLE_WIFI = "ACTION_TOGGLE_WIFI"
        const val ACTION_TOGGLE_BT = "ACTION_TOGGLE_BT"
        const val ACTION_GO_BACK = "ACTION_GO_BACK"
        const val ACTION_GO_HOME = "ACTION_GO_HOME"
        const val ACTION_LOCK_SCREEN = "ACTION_LOCK_SCREEN"
        const val ACTION_READ_SCREEN = "ACTION_READ_SCREEN"
    }

    private lateinit var soundPool: SoundPool
    private var beepStartId: Int = 0
    private var beepSuccessId: Int = 0
    private var beepFailId: Int = 0

    private var pendingAction: String? = null
    private var pendingTargetIndex: Int = -1
    private var pendingTargetText: String? = null

    override fun onCreate() {
        super.onCreate()
        val attr = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        soundPool = SoundPool.Builder()
            .setMaxStreams(5)
            .setAudioAttributes(attr)
            .build()
        // Assets should be in android/app/src/main/assets
        beepStartId = soundPool.load(this, R.raw.beep_start, 1)
        beepSuccessId = soundPool.load(this, R.raw.beep_success, 1)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_TAKE_SCREENSHOT -> takeScreenshotWrapper()
            ACTION_BEEP_START -> playBeep(beepStartId)
            ACTION_BEEP_SUCCESS -> playBeep(beepSuccessId)
            ACTION_TYPE_TEXT -> {
                val text = intent.getStringExtra("text") ?: ""
                typeIntoFocusedNode(text)
            }
            ACTION_CLOSE_APP -> {
                val appName = intent.getStringExtra("appName") ?: ""
                closeAppLogic(appName)
            }
            ACTION_CLICK_INDEX -> {
                val index = intent.getIntExtra("index", 0)
                pendingAction = ACTION_CLICK_INDEX
                pendingTargetIndex = index
            }
            ACTION_TOGGLE_WIFI -> {
                pendingAction = ACTION_TOGGLE_WIFI
            }
            ACTION_TOGGLE_BT -> {
                pendingAction = ACTION_TOGGLE_BT
            }
            ACTION_CLICK_TEXT -> {
                pendingAction = ACTION_CLICK_TEXT
                pendingTargetText = intent.getStringExtra("text")
            }
            ACTION_GO_BACK -> performGlobalAction(GLOBAL_ACTION_BACK)
            ACTION_GO_HOME -> performGlobalAction(GLOBAL_ACTION_HOME)
            ACTION_LOCK_SCREEN -> {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                    performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
                }
            }
            ACTION_READ_SCREEN -> {
                readScreenText()
            }
        }
        return START_STICKY
    }

    private fun playBeep(soundId: Int) {
        if (soundId != 0) {
            soundPool.play(soundId, 1f, 1f, 1, 0, 1f)
        }
    }

    private fun takeScreenshotWrapper() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            performGlobalAction(GLOBAL_ACTION_TAKE_SCREENSHOT)
        }
    }

    private fun closeAppLogic(appName: String) {
        if (appName.lowercase() == "vanimitra" || appName.lowercase() == "vaanimitra") {
            // Self-termination for privacy
            System.exit(0)
            return
        }
        // 1. Open Recents
        performGlobalAction(GLOBAL_ACTION_RECENTS)
        // 2. Wait for Recents to populate (short delay)
        Handler(Looper.getMainLooper()).postDelayed({
            val root = rootInActiveWindow ?: return@postDelayed
            val nodes = root.findAccessibilityNodeInfosByText(appName)
            if (nodes != null && nodes.isNotEmpty()) {
                // Find the parent container that represents the app card and swipe it
                // Infinix optimization: more aggressive swipe
                val swipePath = Path().apply {
                    moveTo(540f, 1600f) // Start lower
                    lineTo(540f, 100f)  // End higher
                }
                val gesture = GestureDescription.Builder()
                    .addStroke(GestureDescription.StrokeDescription(swipePath, 0, 300)) // Faster
                    .build()
                dispatchGesture(gesture, object : GestureResultCallback() {
                    override fun onCompleted(gestureDescription: GestureDescription?) {
                        super.onCompleted(gestureDescription)
                        Log.d("Vanimitra", "Swipe completed")
                    }
                }, null)
            } else {
                // Fallback: If app name specifically not found, swipe middle anyway
                val swipePath = Path().apply {
                    moveTo(540f, 1600f)
                    lineTo(540f, 100f)
                }
                val gesture = GestureDescription.Builder()
                    .addStroke(GestureDescription.StrokeDescription(swipePath, 0, 300))
                    .build()
                dispatchGesture(gesture, null, null)
            }
        }, 800)
    }

    private fun clickIndexInContainer(index: Int) {
        val root = rootInActiveWindow ?: return
        // Find common gallery/grid containers
        val containers = mutableListOf<AccessibilityNodeInfo>()
        findContainers(root, containers)
        
        if (containers.isNotEmpty()) {
            val targetContainer = containers[0] // Assume first large grid is the gallery
            if (index < targetContainer.childCount) {
                targetContainer.getChild(index)?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            }
        }
    }

    private fun findContainers(node: AccessibilityNodeInfo, list: MutableList<AccessibilityNodeInfo>) {
        if (node.className?.contains("GridView") == true || node.className?.contains("RecyclerView") == true) {
            list.add(node)
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) findContainers(child, list)
        }
    }

    private fun typeIntoFocusedNode(text: String) {
        val root = rootInActiveWindow ?: return
        val focusedNode = findFocusedNode(root)
        if (focusedNode != null) {
            val arguments = Bundle()
            arguments.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
            focusedNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
        }
    }

    private fun findFocusedNode(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isFocused) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                val result = findFocusedNode(child)
                if (result != null) return result
            }
        }
        return null
    }

    private fun readScreenText() {
        val root = rootInActiveWindow ?: return
        val builder = StringBuilder()
        traverseAndCollectText(root, builder)
        val text = builder.toString().trim()
        
        val intent = Intent("com.vanimitra.app.SCREEN_TEXT")
        intent.putExtra("text", text)
        sendBroadcast(intent)
    }

    private fun traverseAndCollectText(node: AccessibilityNodeInfo?, builder: StringBuilder) {
        if (node == null) return
        if (node.text != null && node.text.isNotEmpty()) {
            builder.append(node.text).append(". ")
        } else if (node.contentDescription != null && node.contentDescription.isNotEmpty()) {
            builder.append(node.contentDescription).append(". ")
        }
        for (i in 0 until node.childCount) {
            traverseAndCollectText(node.getChild(i), builder)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            when (pendingAction) {
                ACTION_TOGGLE_WIFI, ACTION_TOGGLE_BT -> handleToggleAutomation()
                ACTION_CLICK_INDEX -> handleClickIndexAutomation()
                ACTION_CLICK_TEXT -> handleClickTextAutomation()
            }
        }
    }

    private fun handleToggleAutomation() {
        val root = rootInActiveWindow ?: return
        // Look for common switch widget IDs or text
        val nodes = root.findAccessibilityNodeInfosByViewId("android:id/switch_widget")
        val targets = if (nodes.isNullOrEmpty()) {
             // Fallback to text searching for "Off" or "On" near a known settings term
             root.findAccessibilityNodeInfosByText("OFF") + 
             root.findAccessibilityNodeInfosByText("ON")
        } else nodes

        for (node in targets) {
            if (node != null && (node.isClickable || node.parent?.isClickable == true)) {
                val toClick = if (node.isClickable) node else node.parent
                toClick.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                Log.d("Vanimitra", "Toggle automation successful")
                pendingAction = null
                return
            }
        }
    }

    private fun handleClickIndexAutomation() {
        val root = rootInActiveWindow ?: return
        val containers = mutableListOf<AccessibilityNodeInfo>()
        findContainers(root, containers)
        if (containers.isNotEmpty()) {
            val targetContainer = containers[0]
            if (pendingTargetIndex < targetContainer.childCount) {
                targetContainer.getChild(pendingTargetIndex)?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                Log.d("Vanimitra", "Click index automation successful")
                pendingAction = null
            }
        }
    }
    private fun handleClickTextAutomation() {
        val root = rootInActiveWindow ?: return
        val text = pendingTargetText ?: return
        val nodes = root.findAccessibilityNodeInfosByText(text)
        if (!nodes.isNullOrEmpty()) {
            for (node in nodes) {
                if (node.isClickable || node.parent?.isClickable == true) {
                    val toClick = if (node.isClickable) node else node.parent
                    toClick.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    Log.d("Vanimitra", "Click text automation successful: $text")
                    pendingAction = null
                    return
                }
            }
        }
    }
    override fun onInterrupt() {}
}
