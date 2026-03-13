class VConstants {
  // Model
  static const modelFileName = 'vanimitra-v1.0-qwen0.5b-q4km.gguf';
  static const fallbackModelFileName = 'qwen2.5-0.5b-instruct-q4_k_m.gguf';
  static const nCtx = 512;
  static const maxTokens = 80;
  static const temperature = 0.1;

  // Wake word
  static const wakeWordAsset = 'assets/wake_word/vaani_android.ppn';
  static const wakeWordSensitivity = 0.7;
  static const wakeWordDebounceMs = 3000;

  // Dialogue
  static const clarificationTimeoutSec = 8;
  static const maxClarificationAttempts = 2;
  static const maxConsecutiveMisses = 2;
  static const postExecutionResumeDelayMs = 300;

  // Cache
  static const maxCacheContextTokens = 100;
  static const cacheContextLimit = 8;
  static const maxCacheEntries = 50;

  // Personalisation
  static const minFailuresForFinetune = 50;
  static const minBatteryPct = 80;

  // System prompt — MUST match ml/training/train.py exactly
  static const systemPrompt = '''You are a voice command parser for a smartphone assistant.
The user speaks in Hindi, Tamil, or English (or mixed/code-switched).
Output ONLY a single valid JSON object with 'intent' and 'params'.
Valid intents: FLASHLIGHT_ON, FLASHLIGHT_OFF, VOLUME_UP, VOLUME_DOWN, CALL_CONTACT, SET_ALARM, SEND_WHATSAPP, OPEN_APP, NAVIGATE, TOGGLE_WIFI, TOGGLE_BLUETOOTH, GO_HOME, GO_BACK, LOCK_SCREEN, TAKE_SCREENSHOT, UNKNOWN''';

  // App package names
  static const Map<String, String> appPackages = {
    'chrome'    : 'com.android.chrome',
    'youtube'   : 'com.google.android.youtube',
    'whatsapp'  : 'com.whatsapp',
    'settings'  : 'com.android.settings',
    'camera'    : 'com.android.camera2',
    'maps'      : 'com.google.android.apps.maps',
    'phone'     : 'com.android.dialer',
    'messages'  : 'com.google.android.apps.messaging',
    'spotify'   : 'com.spotify.music',
    'instagram' : 'com.instagram.android',
    'gmail'     : 'com.google.android.gm',
    'calendar'  : 'com.google.android.calendar',
  };
}
