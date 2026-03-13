// lib/features/actions/app_registry.dart
//
// FIX #4 + #7: Expanded registry with correct package IDs and aliases.
// Camera fix: com.android.camera2 is the AOSP package. Most OEM devices
// use their own camera package. We try multiple known packages.

class AppRegistry {
  AppRegistry._();

  // Primary package map: spoken name → package ID
  static const Map<String, String> _packages = {
    // Google apps
    'chrome':        'com.android.chrome',
    'google chrome': 'com.android.chrome',
    'youtube':       'com.google.android.youtube',
    'maps':          'com.google.android.apps.maps',
    'google maps':   'com.google.android.apps.maps',
    'gmail':         'com.google.android.gm',
    'calendar':      'com.google.android.calendar',
    'google calendar':'com.google.android.calendar',
    'drive':         'com.google.android.apps.docs',
    'google drive':  'com.google.android.apps.docs',
    'photos':        'com.google.android.apps.photos',
    'google photos': 'com.google.android.apps.photos',
    'meet':          'com.google.android.apps.meetings',
    'google meet':   'com.google.android.apps.meetings',
    'translate':     'com.google.android.apps.translate',

    // Messaging & social
    'whatsapp':      'com.whatsapp',
    'whatsapp business':'com.whatsapp.w4b',
    'telegram':      'org.telegram.messenger',
    'instagram':     'com.instagram.android',
    'facebook':      'com.facebook.katana',
    'twitter':       'com.twitter.android',
    'x':             'com.twitter.android',
    'snapchat':      'com.snapchat.android',
    'linkedin':      'com.linkedin.android',
    'truecaller':    'com.truecaller',

    // Phone & messages
    'phone':         'com.google.android.dialer',
    'dialer':        'com.google.android.dialer',
    'messages':      'com.google.android.apps.messaging',
    'sms':           'com.google.android.apps.messaging',

    // Settings & system
    'settings':      'com.android.settings',

    // Camera — FIX #4: try CATEGORY_LAUNCHER which finds the OEM camera
    // The _cameraPackages list below is used as fallback
    'camera':        'com.android.camera2',

    // Calculator — FIX #4: was opening wrong activity
    'calculator':    'com.android.calculator2',

    // Music & entertainment
    'spotify':       'com.spotify.music',
    'netflix':       'com.netflix.mediaclient',
    'prime video':   'com.amazon.avod.thirdpartyclient',
    'hotstar':       'in.startv.hotstar',
    'zee5':          'com.graymatrix.did',
    'jio cinema':    'com.jio.jiocinema',

    // Payments & finance
    'gpay':          'com.google.android.apps.nbu.paisa.user',
    'google pay':    'com.google.android.apps.nbu.paisa.user',
    'phonepe':       'com.phonepe.app',
    'paytm':         'net.one97.paytm',

    // Utilities
    'clock':         'com.google.android.deskclock',
    'alarm':         'com.google.android.deskclock',
    'files':         'com.google.android.apps.nbu.files',
    'file manager':  'com.google.android.apps.nbu.files',
    'contacts':      'com.google.android.contacts',
    'playstore':     'com.android.vending',
    'play store':    'com.android.vending',
    'store':         'com.android.vending',
    'gallery':       'com.google.android.apps.photos',
    'gallery app':   'com.google.android.apps.photos',
  };

  // Hindi aliases
  static const Map<String, String> _hindiAliases = {
    'कैमरा':    'camera',
    'सेटिंग':   'settings',
    'कैलकुलेटर':'calculator',
    'घड़ी':     'clock',
    'फ़ोन':     'phone',
    'मैसेज':    'messages',
    'फ़ोटो':    'photos',
    'नक्शा':    'maps',
  };

  // Tamil aliases
  static const Map<String, String> _tamilAliases = {
    'கேமரா':    'camera',
    'அமைப்புகள்':'settings',
    'கணக்கி':   'calculator',
    'கடிகாரம்': 'clock',
    'தொலைபேசி': 'phone',
    'செய்திகள்':'messages',
    'படங்கள்':  'photos',
    'வரைபடம்':  'maps',
  };

  /// Resolves a spoken app name to an Android package ID.
  /// Returns null if not found.
  static String? resolvePackage(String appName) {
    final key = appName.toLowerCase().trim();

    // Direct lookup
    if (_packages.containsKey(key)) return _packages[key];

    // Hindi alias
    if (_hindiAliases.containsKey(appName.trim())) {
      final en = _hindiAliases[appName.trim()]!;
      return _packages[en];
    }

    // Tamil alias
    if (_tamilAliases.containsKey(appName.trim())) {
      final en = _tamilAliases[appName.trim()]!;
      return _packages[en];
    }

    // Fuzzy: check if any known key is contained in the spoken name
    // e.g. "open the youtube app" → contains "youtube"
    for (final entry in _packages.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// For camera specifically, returns multiple candidate packages to try in order.
  static List<String> cameraPackageCandidates() => [
    'com.android.camera2',        // AOSP
    'com.google.android.camera',  // Pixel
    'com.sec.android.app.camera', // Samsung
    'com.huawei.camera',          // Huawei
    'com.zte.camera',             // ZTE
    'com.transsion.camera',       // Infinix/Tecno/itel (your demo device!)
    'com.mediatek.camera',        // MediaTek generic
  ];
}
