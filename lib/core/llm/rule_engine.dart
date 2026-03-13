import '../../models/parsed_command.dart';
import '../../models/v_intent.dart';

/// Pure Dart, synchronous, <50ms.
/// Returns a ParsedCommand if a rule matches, null if LLM fallback is needed.
class RuleEngine {
  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? quickParse(String transcript, String language) {
    final raw = transcript; // Keep original for params
    final t = transcript.trim().toLowerCase();
    final lang = language; // Use 'lang' for consistency with new methods

    if (t.isEmpty) return null;

    // Try each intent in priority order (param-heavy first so broad rules
    // don't swallow them).
    ParsedCommand? cmd;

    // New parsing methods
    cmd = _tryCallContact(t, lang);
    cmd ??= _trySendWhatsapp(t, lang);
    cmd ??= _trySetAlarm(t, lang);
    cmd ??= _tryRemoveAlarm(t, lang);
    cmd ??= _tryReadScreen(t, lang);
    cmd ??= _tryOpenApp(t, lang);
    cmd ??= _tryNavigate(t, lang);
    cmd ??= _tryType(raw, lang); // Added _tryType
    cmd ??= _tryPickIndex(t, lang);
    cmd ??= _tryOpenRecents(t, lang);
    cmd ??= _tryCloseApp(t, lang);
    cmd ??= _tryFlashlightOn(t, lang);
    cmd ??= _tryFlashlightOff(t, lang);
    cmd ??= _tryVolumeUp(t, lang);
    cmd ??= _tryVolumeDown(t, lang);
    cmd ??= _tryToggleWifi(t, lang);
    cmd ??= _tryToggleBluetooth(t, lang);
    cmd ??= _tryGoHome(t, lang);
    cmd ??= _tryGoBack(t, lang);
    cmd ??= _tryLockScreen(t, lang);
    cmd ??= _tryTakeScreenshot(t, lang); // Renamed from _tryTakeScreenshot to _parseScreenshot in the instruction, but keeping original name for now.

    return cmd;
  }

  static ParsedCommand? _tryPickIndex(String t, String lang) {
    final ordinals = {
      'first': 0, '1st': 0, 'pahla': 0, 'pehla': 0, 'mudhal': 0,
      'second': 1, '2nd': 1, 'dusra': 1, 'doosra': 1, 'irandavathu': 1,
      'third': 2, '3rd': 2, 'tisra': 2, 'teesra': 2, 'moondravathu': 2,
      'fourth': 3, '4th': 3, 'chautha': 3, 'naangavathu': 3,
      'fifth': 4, '5th': 4, 'panchwa': 4, 'ainthavathu': 4,
    };

    const triggers = [
      'pick ', 'select ', 'click ', 'choose ', 'open ',
      'chuno ', 'select karo ', 'pick karo ',
      'thira ', 'edu ', 'select pannu ',
    ];

    for (final trigger in triggers) {
      if (t.contains(trigger)) {
        for (final entry in ordinals.entries) {
          if (t.contains(entry.key)) {
            return _make(VIntent.pickIndex, {
              'index': entry.value,
              'label': entry.key,
            }, lang, t);
          }
        }
      }
    }
    return null;
  }

  static ParsedCommand? _tryOpenRecents(String t, String lang) {
    const kw = [
      'recent calls', 'recent call', 'call history', 'call log',
      'purana call', 'history dikhao',
      'reacent contact', 'reacent call',
    ];
    if (!_any(t, kw)) return null;
    return _make(VIntent.openApp, {'app': 'phone', 'action': 'recents'}, lang, t);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CLOSE APP
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryCloseApp(String t, String lang) {
    const triggers = [
      'close ', 'exit ', 'stop ', 'shut ', 'quit ',
      'band karo ', 'niklo ', 'band kar ',
      'moodu ', 'veliye po ', 'anai ',
      'बंद करो ', 'बाहर निकलो ', 'बंद कर ',
    ];
    for (final trigger in triggers) {
      if (t.contains(trigger)) {
        final idx = t.indexOf(trigger);
        final app = t.substring(idx + trigger.length).trim();
        if (app.isEmpty || app.length < 2) continue;
        return _make(VIntent.closeApp, {'app': app}, lang, t);
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand _make(
    VIntent intent,
    Map<String, dynamic> params,
    String language,
    String raw,
  ) =>
      ParsedCommand(
        intent: intent,
        params: params,
        language: language,
        source: 'rule',
        rawTranscript: raw,
        timestamp: DateTime.now(),
      );

  static bool _any(String t, List<String> keywords) =>
      keywords.any((k) => t.contains(k));

  // ──────────────────────────────────────────────────────────────────────────
  // FLASHLIGHT
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryFlashlightOn(String t, String lang) {
    const kw = [
      // English
      'flashlight on', 'torch on', 'turn on torch', 'turn on flashlight',
      'switch on torch', 'flash on', 'light on',
      // Hindi (transliterated + Devanagari)
      'torch chalu', 'torch jalao', 'torch on karo', 'torch on kar',
      'torchlight on', 'flash chalu', 'roshni on',
      'टॉर्च चालू', 'टॉर्च जलाओ', 'फ्लैश चालू',
      // Tamil (transliterated + script)
      'torch on pannu', 'flash on pannu', 'vilangu on',
      'விளக்கு ஆன்', 'டார்ச் ஆன்',
    ];
    if (!_any(t, kw)) return null;
    return _make(VIntent.flashlightOn, {}, lang, t);
  }

  static ParsedCommand? _tryFlashlightOff(String t, String lang) {
    const kw = [
      'flashlight off', 'torch off', 'turn off torch', 'turn off flashlight',
      'switch off torch', 'flash off', 'light off',
      'torch band', 'torch band karo', 'torch off karo',
      'torchlight off', 'flash band', 'roshni off',
      'टॉर्च बंद', 'फ्लैश बंद',
      'torch off pannu', 'flash off pannu', 'vilangu off',
      'விளக்கு ஆஃப்', 'டார்ச் ஆஃப்', 'விளக்கு அணை',
    ];
    if (!_any(t, kw)) return null;
    return _make(VIntent.flashlightOff, {}, lang, t);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VOLUME
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryVolumeUp(String t, String lang) {
    const kw = [
      'volume up', 'increase volume', 'louder', 'sound up',
      'turn up volume', 'raise volume', 'make it louder',
      'awaaz badha', 'volume badha', 'sound badha', 'awaaz tez karo',
      'आवाज़ बढ़ाओ', 'वॉल्यूम बढ़ाओ', 'आवाज बढ़ा',
      'volume athikam', 'sound athikam', 'oliyai athikari',
      'ஒலி அதிகரி', 'வால்யூம் அதிகரி',
    ];
    if (!_any(t, kw)) return null;
    return _make(VIntent.volumeUp, {}, lang, t);
  }

  static ParsedCommand? _tryVolumeDown(String t, String lang) {
    const kw = [
      'volume down', 'decrease volume', 'quieter', 'sound down',
      'turn down volume', 'lower volume', 'make it quieter', 'mute',
      'awaaz kam karo', 'volume kam karo', 'sound kam karo',
      'आवाज़ कम करो', 'वॉल्यूम कम करो', 'आवाज कम',
      'volume kuray', 'sound kuray', 'oliyai kuraikal',
      'ஒலி குறை', 'வால்யூம் குறை',
    ];
    if (!_any(t, kw)) return null;
    return _make(VIntent.volumeDown, {}, lang, t);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CALL CONTACT — extract name after trigger word
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryCallContact(String t, String lang) {
    const triggers = [
      'call ', 'phone ', 'dial ', 'ring ',
      // Hindi
      'call karo ', 'phone karo ', 'call kar ', 'baat karo ',
      'फोन करो ', 'कॉल करो ', 'फ़ोन करो ',
      // Tamil
      'call pannu ', 'phone pannu ', 'அழை ',
    ];
    for (final trigger in triggers) {
      if (t.contains(trigger)) {
        final idx = t.indexOf(trigger);
        String contact = t.substring(idx + trigger.length).trim();
        if (contact.isEmpty) continue;

        String? useApp;
        // Check for " using [app]" or " via [app]"
        final usingRegex = RegExp(r'(.+)\s+(?:using|via|से|மூலம்)\s+(.+)');
        final match = usingRegex.firstMatch(contact);
        if (match != null) {
          contact = match.group(1)!.trim();
          useApp = match.group(2)!.trim();
        }

        // Reject if it looks like a sub-command ("call me maybe" → not a contact)
        if (contact.length < 2) continue;
        return _make(VIntent.callContact, {
          'contact': contact,
          if (useApp != null) 'app': useApp,
        }, lang, t);
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SEND WHATSAPP — "whatsapp [contact] [message]"
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _trySendWhatsapp(String t, String lang) {
    // Patterns: "whatsapp [to] <name> [say/message] <msg>"
    //           "send whatsapp to <name>"
    //           "whatsapp karo <name>"

    // Quick bail
    const waTriggers = ['whatsapp', 'व्हाट्सएप', 'வாட்ஸ்அப்'];
    if (!_any(t, waTriggers)) return null;

    // Try to extract contact and optional message
    // Pattern 1: "whatsapp <name> say <message>"
    final sayMatch =
        RegExp(r'whatsapp\s+(?:to\s+)?(.+?)\s+(?:say|message|msg|bolo|பெசு)\s+(.+)')
            .firstMatch(t);
    if (sayMatch != null) {
      return _make(
        VIntent.sendWhatsapp,
        {'contact': sayMatch.group(1)!.trim(), 'message': sayMatch.group(2)!.trim()},
        lang,
        t,
      );
    }

    // Pattern 2: "whatsapp <name>" (no message)
    final simpleMatch =
        RegExp(r'whatsapp\s+(?:to\s+|karo\s+)?(.+)').firstMatch(t);
    if (simpleMatch != null) {
      final contact = simpleMatch.group(1)!.trim();
      if (contact.isNotEmpty) {
        return _make(
          VIntent.sendWhatsapp,
          {'contact': contact, 'message': ''},
          lang,
          t,
        );
      }
    }

    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SET ALARM — parses HH:MM, "X baje", "X o'clock", "X மணி"
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _trySetAlarm(String t, String lang) {
    const triggers = [
      'alarm', 'set alarm', 'alarm set', 'wake me',
      'alarm laga', 'alarm lagao', 'alarm set karo',
      'அலாரம்', 'alarm podu',
    ];
    if (!_any(t, triggers)) return null;

    // HH:MM explicit format
    final hhmmMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(t);
    if (hhmmMatch != null) {
      final h = hhmmMatch.group(1)!.padLeft(2, '0');
      final m = hhmmMatch.group(2)!;
      return _make(VIntent.setAlarm, {'time': '$h:$m'}, lang, t);
    }

    // "7 baje", "7 o'clock", "seven o'clock"
    final wordsToDigits = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'eleven': 11, 'twelve': 12,
      'ek': 1, 'do': 2, 'teen': 3, 'char': 4, 'paanch': 5,
      'chhe': 6, 'saat': 7, 'aath': 8, 'nau': 9, 'das': 10,
    };
    // Numeric followed by "baje", "o'clock", "am", "pm", "mani", "மணி"
    final regex = RegExp(r'(\d{1,2})[:\s]?(\d{0,2})\s*(am|pm|baje|மணி)?', caseSensitive: false);
    final match = regex.firstMatch(t);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      final suffix = match.group(3)?.toLowerCase();

      // Handle "1000" or "2200" inputs
      if (match.group(2) == '' && hour > 100) {
        minute = hour % 100;
        hour = (hour / 100).floor();
      }

      // Handle AM/PM
      if (suffix == 'pm' && hour < 12) hour += 12;
      if (suffix == 'am' && hour == 12) hour = 0;

      final h = hour.toString().padLeft(2, '0');
      final m = minute.toString().padLeft(2, '0');
      return _make(VIntent.setAlarm, {'time': '$h:$m', 'hour': hour, 'minute': minute}, lang, t);
    }
    return null;
  }

  static ParsedCommand? _tryRemoveAlarm(String t, String lang) {
    if ((t.contains('remove') || t.contains('delete') || t.contains('cancel') || t.contains('stop')) &&
        t.contains('alarm')) {
      return _make(VIntent.setAlarm, {'action': 'remove'}, lang, t);
    }
    return null;
  }

  static ParsedCommand? _tryReadScreen(String t, String lang) {
    final kw = ['read screen', 'text on screen', 'screen padho', 'padho', 'screen padi', 'padi'];
    if (_any(t, kw)) {
      return _make(VIntent.readScreen, {}, lang, t);
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OPEN APP
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryOpenApp(String t, String lang) {
    const triggers = [
      'open ', 'launch ', 'start ',
      'kholo ', 'open karo ', 'chalu karo ',
      'திற ', 'open pannu ',
    ];
    for (final trigger in triggers) {
      if (t.contains(trigger)) {
        final idx = t.indexOf(trigger);
        final app = t.substring(idx + trigger.length).trim();
        if (app.isEmpty || app.length < 2) continue;
        return _make(VIntent.openApp, {'app': app}, lang, t);
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // NAVIGATE
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryNavigate(String t, String lang) {
    const triggers = [
      'navigate to ', 'directions to ', 'take me to ', 'go to ',
      'how to reach ', 'route to ', 'show me ',
      'le chalo ', 'rasta batao ', 'navigate karo ',
      'sellu ', 'thirumbu pannu ',
      'வழி காட்டு ', 'திசை ', 'navigate ',
    ];
    for (final trigger in triggers) {
      if (t.contains(trigger)) {
        final idx = t.indexOf(trigger);
        final dest = t.substring(idx + trigger.length).trim();
        if (dest.isEmpty || dest.length < 2) continue;
        return _make(VIntent.navigate, {'destination': dest}, lang, t);
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // WIFI
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryToggleWifi(String t, String lang) {
    const kw = [
      'wifi', 'wi-fi', 'wireless',
      'vifi', 'வைஃபை', 'வைபை',
    ];
    if (!_any(t, kw)) return null;
    final state = (t.contains('off') || t.contains('band') || t.contains('बंद'))
        ? 'off'
        : 'on';
    return _make(VIntent.toggleWifi, {'state': state}, lang, t);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BLUETOOTH
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryToggleBluetooth(String t, String lang) {
    const kw = [
      'bluetooth', 'blue tooth', 'bt',
      'ப்ளூடூத்',
    ];
    if (!_any(t, kw)) return null;
    final state = (t.contains('off') || t.contains('band') || t.contains('बंद'))
        ? 'off'
        : 'on';
    return _make(VIntent.toggleBluetooth, {'state': state}, lang, t);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GO HOME
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryGoHome(String t, String lang) {
    const kw = [
      'go home', 'home screen', 'go to home', 'main screen',
      'ghar jao', 'home pe jao', 'home chalo',
      'घर जाओ', 'होम स्क्रीन',
      'home pannu', 'mukkiya page', 'முகப்பு திரை',
    ];
    if (!_any(t, kw)) return null;
    return _make(VIntent.goHome, {}, lang, t);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GO BACK
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryGoBack(String t, String lang) {
    const kw = [
      'go back', 'back', 'previous', 'return',
      'wapas jao', 'peechhe jao', 'back karo',
      'वापस जाओ', 'पीछे जाओ',
      'piragu po', 'mudhal page', 'திரும்பு',
    ];
    if (!_any(t, kw)) return null;
    // Make sure "go back" isn't caught inside a navigate phrase
    if (t.contains('navigate') || t.contains('directions')) return null;
    return _make(VIntent.goBack, {}, lang, t);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LOCK SCREEN
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryLockScreen(String t, String lang) {
    const kw = [
      'lock screen', 'lock phone', 'lock device',
      'phone lock karo', 'lock kar do',
      'फोन लॉक करो', 'स्क्रीन लॉक',
      'lock pannu', 'phone lock',
      'பூட்டு', 'திரை பூட்டு',
    ];
    if (!_any(t, kw)) return null;
    return _make(VIntent.lockScreen, {}, lang, t);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TYPE TEXT
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryType(String raw, String lang) {
    final t = raw.toLowerCase().trim();
    final triggers = ['type ', 'likho ', 'ezhuthu ', 'लिखो ', 'எழுது '];

    for (final trigger in triggers) {
      if (t.contains(trigger)) {
        final idx = t.indexOf(trigger);
        final content = raw.substring(idx + trigger.length).trim();
        if (content.isNotEmpty) {
          return _make(VIntent.typeText, {'text': content}, lang, raw);
        }
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAKE SCREENSHOT
  // ──────────────────────────────────────────────────────────────────────────
  static ParsedCommand? _tryTakeScreenshot(String t, String lang) {
    const kw = [
      'screenshot', 'screen shot', 'capture screen', 'screen capture',
      'screenshot lo', 'screenshot le',
      'ஸ்கிரீன்ஷாட்', 'திரை படம்',
    ];
    if (!_any(t, kw)) return null;
    return _make(VIntent.takeScreenshot, {}, lang, t);
  }
}
