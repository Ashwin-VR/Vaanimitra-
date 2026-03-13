// lib/app/constants.dart

class VConstants {
  VConstants._();

  // Packages for OpenApp intent
  static const Map<String, String> appPackages = {
    'chrome':     'com.android.chrome',
    'youtube':    'com.google.android.youtube',
    'whatsapp':   'com.whatsapp',
    'settings':   'com.android.settings',
    'camera':     'com.android.camera2',
    'maps':       'com.google.android.apps.maps',
    'phone':      'com.android.dialer',
    'messages':   'com.google.android.apps.messaging',
    'spotify':    'com.spotify.music',
    'instagram':  'com.instagram.android',
    'gmail':      'com.google.android.gm',
    'calendar':   'com.google.android.calendar',
  };

  // Pipeline Settings
  static const int postExecutionResumeDelayMs = 1500;
  static const int maxClarificationAttempts = 2; // Double miss threshold
  static const int cacheContextLimit = 10;
  static const int maxCacheEntries = 1000;
  
  // Wake Word (Porcupine)
  static const String wakeWordAsset = 'assets/wake_word/vanimitra.ppn';
  static const double wakeWordSensitivity = 0.5;
  static const int wakeWordDebounceMs = 2000;

  // LLM Settings
  static const String modelFileName = 'vanimitra-llm-q4.gguf';
  static const String fallbackModelFileName = 'phi-2-q4.gguf';
  static const int nCtx = 1024;
  static const int maxTokens = 64;
  
  static const String systemPrompt = """
Your name is Vaanimitra. You are an offline assistant for Android.
Return ONLY a JSON object with "intent" and "params".
Intents: FLASHLIGHT_ON, FLASHLIGHT_OFF, VOLUME_UP, VOLUME_DOWN, CALL_CONTACT, SET_ALARM, SEND_WHATSAPP, OPEN_APP, NAVIGATE, TOGGLE_WIFI, TOGGLE_BLUETOOTH, GO_HOME, GO_BACK, LOCK_SCREEN.
""";
}
