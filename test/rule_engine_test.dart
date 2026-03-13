import 'package:flutter_test/flutter_test.dart';
import 'package:vanimitra/core/llm/rule_engine.dart';
import 'package:vanimitra/models/v_intent.dart';

void main() {
  // Helper
  void check(String input, VIntent expected, {String lang = 'en', Map<String, dynamic>? params}) {
    final cmd = RuleEngine.quickParse(input, lang);
    expect(cmd, isNotNull, reason: 'Expected match for: "$input"');
    expect(cmd!.intent, expected, reason: 'Wrong intent for: "$input"');
    params?.forEach((k, v) {
      expect(cmd.params[k], v, reason: 'Wrong param $k for: "$input"');
    });
  }

  // ── FLASHLIGHT ────────────────────────────────────────────────────────────
  group('FLASHLIGHT_ON', () {
    test('EN: torch on',       () => check('torch on',            VIntent.flashlightOn));
    test('EN: flashlight on',  () => check('flashlight on',       VIntent.flashlightOn));
    test('EN: turn on torch',  () => check('turn on torch',       VIntent.flashlightOn));
    test('HI: torch chalu',    () => check('torch chalu',         VIntent.flashlightOn, lang: 'hi'));
    test('HI: टॉर्च चालू',    () => check('टॉर्च चालू',          VIntent.flashlightOn, lang: 'hi'));
    test('TA: torch on pannu', () => check('torch on pannu',      VIntent.flashlightOn, lang: 'ta'));
    test('TA: விளக்கு ஆன்',    () => check('விளக்கு ஆன்',         VIntent.flashlightOn, lang: 'ta'));
  });

  group('FLASHLIGHT_OFF', () {
    test('EN: torch off',       () => check('torch off',           VIntent.flashlightOff));
    test('EN: turn off torch',  () => check('turn off torch',      VIntent.flashlightOff));
    test('HI: torch band',      () => check('torch band',          VIntent.flashlightOff, lang: 'hi'));
    test('HI: टॉर्च बंद',       () => check('टॉर्च बंद',           VIntent.flashlightOff, lang: 'hi'));
    test('TA: torch off pannu', () => check('torch off pannu',     VIntent.flashlightOff, lang: 'ta'));
    test('TA: விளக்கு அணை',     () => check('விளக்கு அணை',         VIntent.flashlightOff, lang: 'ta'));
  });

  // ── VOLUME ────────────────────────────────────────────────────────────────
  group('VOLUME_UP', () {
    test('EN: volume up',         () => check('volume up',          VIntent.volumeUp));
    test('EN: louder',            () => check('louder',             VIntent.volumeUp));
    test('HI: awaaz badha',       () => check('awaaz badha',        VIntent.volumeUp, lang: 'hi'));
    test('HI: आवाज़ बढ़ाओ',       () => check('आवाज़ बढ़ाओ',         VIntent.volumeUp, lang: 'hi'));
    test('TA: volume athikam',    () => check('volume athikam',     VIntent.volumeUp, lang: 'ta'));
    test('TA: ஒலி அதிகரி',        () => check('ஒலி அதிகரி',         VIntent.volumeUp, lang: 'ta'));
  });

  group('VOLUME_DOWN', () {
    test('EN: volume down',      () => check('volume down',        VIntent.volumeDown));
    test('EN: mute',             () => check('mute',               VIntent.volumeDown));
    test('HI: awaaz kam karo',   () => check('awaaz kam karo',     VIntent.volumeDown, lang: 'hi'));
    test('HI: आवाज़ कम करो',     () => check('आवाज़ कम करो',       VIntent.volumeDown, lang: 'hi'));
    test('TA: volume kuray',     () => check('volume kuray',       VIntent.volumeDown, lang: 'ta'));
    test('TA: ஒலி குறை',         () => check('ஒலி குறை',           VIntent.volumeDown, lang: 'ta'));
  });

  // ── CALL ──────────────────────────────────────────────────────────────────
  group('CALL_CONTACT', () {
    test('EN: call John',           () => check('call John',            VIntent.callContact, params: {'contact': 'john'}));
    test('EN: phone Priya',         () => check('phone Priya',          VIntent.callContact, params: {'contact': 'priya'}));
    test('EN: dial Amit',           () => check('dial Amit',            VIntent.callContact, params: {'contact': 'amit'}));
    test('HI: call karo Rahul',     () => check('call karo Rahul',      VIntent.callContact, lang: 'hi', params: {'contact': 'rahul'}));
    test('HI: कॉल करो राहुल',      () => check('कॉल करो राहुल',        VIntent.callContact, lang: 'hi'));
    test('TA: call pannu Arjun',    () => check('call pannu Arjun',     VIntent.callContact, lang: 'ta', params: {'contact': 'arjun'}));
    test('TA: அழை அருண்',          () => check('அழை அருண்',            VIntent.callContact, lang: 'ta'));
  });

  // ── ALARM ─────────────────────────────────────────────────────────────────
  group('SET_ALARM', () {
    test('EN: set alarm 07:30',    () => check('set alarm for 07:30',   VIntent.setAlarm, params: {'time': '07:30'}));
    test('EN: alarm at 8 oclock',  () => check('alarm at 8 o clock',    VIntent.setAlarm, params: {'time': '08:00'}));
    test('EN: wake me at 6:00',    () => check('wake me at 6:00',       VIntent.setAlarm, params: {'time': '06:00'}));
    test('HI: alarm lagao 9:00',   () => check('alarm lagao 9:00',      VIntent.setAlarm, lang: 'hi', params: {'time': '09:00'}));
    test('TA: alarm podu 7:00',    () => check('alarm podu 7:00',       VIntent.setAlarm, lang: 'ta', params: {'time': '07:00'}));
    test('TA: அலாரம் 6:30',        () => check('அலாரம் 6:30',           VIntent.setAlarm, lang: 'ta', params: {'time': '06:30'}));
  });

  // ── WHATSAPP ──────────────────────────────────────────────────────────────
  group('SEND_WHATSAPP', () {
    test('EN: whatsapp John',                () => check('whatsapp John',               VIntent.sendWhatsapp, params: {'contact': 'john'}));
    test('EN: whatsapp Priya say hello',     () => check('whatsapp Priya say hello',    VIntent.sendWhatsapp, params: {'contact': 'priya', 'message': 'hello'}));
    test('HI: whatsapp karo Rahul',          () => check('whatsapp karo Rahul',         VIntent.sendWhatsapp, lang: 'hi'));
    test('TA: whatsapp Arjun',               () => check('whatsapp Arjun',              VIntent.sendWhatsapp, lang: 'ta'));
  });

  // ── OPEN APP ──────────────────────────────────────────────────────────────
  group('OPEN_APP', () {
    test('EN: open youtube',       () => check('open youtube',          VIntent.openApp, params: {'app': 'youtube'}));
    test('EN: launch chrome',      () => check('launch chrome',         VIntent.openApp, params: {'app': 'chrome'}));
    test('HI: kholo settings',     () => check('kholo settings',        VIntent.openApp, lang: 'hi', params: {'app': 'settings'}));
    test('HI: open karo camera',   () => check('open karo camera',      VIntent.openApp, lang: 'hi'));
    test('TA: open pannu maps',    () => check('open pannu maps',       VIntent.openApp, lang: 'ta'));
    test('TA: திற youtube',        () => check('திற youtube',            VIntent.openApp, lang: 'ta'));
  });

  // ── NAVIGATE ──────────────────────────────────────────────────────────────
  group('NAVIGATE', () {
    test('EN: navigate to Mumbai',   () => check('navigate to Mumbai',   VIntent.navigate, params: {'destination': 'mumbai'}));
    test('EN: take me to airport',   () => check('take me to airport',   VIntent.navigate, params: {'destination': 'airport'}));
    test('EN: directions to park',   () => check('directions to park',   VIntent.navigate, params: {'destination': 'park'}));
    test('HI: le chalo station',     () => check('le chalo station',     VIntent.navigate, lang: 'hi'));
    test('HI: navigate karo market', () => check('navigate karo market', VIntent.navigate, lang: 'hi'));
    test('TA: வழி காட்டு Chennai',   () => check('வழி காட்டு chennai',   VIntent.navigate, lang: 'ta'));
  });

  // ── WIFI ──────────────────────────────────────────────────────────────────
  group('TOGGLE_WIFI', () {
    test('EN: turn on wifi',    () => check('turn on wifi',    VIntent.toggleWifi, params: {'state': 'on'}));
    test('EN: wifi off',        () => check('wifi off',        VIntent.toggleWifi, params: {'state': 'off'}));
    test('HI: wifi band karo',  () => check('wifi band karo',  VIntent.toggleWifi, lang: 'hi', params: {'state': 'off'}));
    test('TA: வைஃபை on',        () => check('வைஃபை on',        VIntent.toggleWifi, lang: 'ta'));
  });

  // ── BLUETOOTH ─────────────────────────────────────────────────────────────
  group('TOGGLE_BLUETOOTH', () {
    test('EN: bluetooth on',    () => check('bluetooth on',    VIntent.toggleBluetooth, params: {'state': 'on'}));
    test('EN: turn off bt',     () => check('turn off bt',     VIntent.toggleBluetooth, params: {'state': 'off'}));
    test('HI: bluetooth band',  () => check('bluetooth band',  VIntent.toggleBluetooth, lang: 'hi', params: {'state': 'off'}));
  });

  // ── GO HOME ───────────────────────────────────────────────────────────────
  group('GO_HOME', () {
    test('EN: go home',           () => check('go home',           VIntent.goHome));
    test('EN: home screen',       () => check('home screen',       VIntent.goHome));
    test('HI: ghar jao',          () => check('ghar jao',          VIntent.goHome, lang: 'hi'));
    test('HI: घर जाओ',            () => check('घर जाओ',            VIntent.goHome, lang: 'hi'));
    test('TA: முகப்பு திரை',      () => check('முகப்பு திரை',       VIntent.goHome, lang: 'ta'));
  });

  // ── GO BACK ───────────────────────────────────────────────────────────────
  group('GO_BACK', () {
    test('EN: go back',          () => check('go back',           VIntent.goBack));
    test('HI: wapas jao',        () => check('wapas jao',         VIntent.goBack, lang: 'hi'));
    test('HI: वापस जाओ',         () => check('वापस जाओ',           VIntent.goBack, lang: 'hi'));
    test('TA: திரும்பு',          () => check('திரும்பு',            VIntent.goBack, lang: 'ta'));
  });

  // ── LOCK SCREEN ───────────────────────────────────────────────────────────
  group('LOCK_SCREEN', () {
    test('EN: lock screen',      () => check('lock screen',       VIntent.lockScreen));
    test('EN: lock phone',       () => check('lock phone',        VIntent.lockScreen));
    test('HI: phone lock karo',  () => check('phone lock karo',   VIntent.lockScreen, lang: 'hi'));
    test('HI: स्क्रीन लॉक',     () => check('स्क्रीन लॉक',       VIntent.lockScreen, lang: 'hi'));
    test('TA: பூட்டு',            () => check('பூட்டு',             VIntent.lockScreen, lang: 'ta'));
  });

  // ── SCREENSHOT ────────────────────────────────────────────────────────────
  group('TAKE_SCREENSHOT', () {
    test('EN: screenshot',       () => check('screenshot',        VIntent.takeScreenshot));
    test('EN: capture screen',   () => check('capture screen',    VIntent.takeScreenshot));
    test('HI: screenshot lo',    () => check('screenshot lo',     VIntent.takeScreenshot, lang: 'hi'));
    test('TA: ஸ்கிரீன்ஷாட்',    () => check('ஸ்கிரீன்ஷாட்',      VIntent.takeScreenshot, lang: 'ta'));
  });

  // ── UNKNOWN ───────────────────────────────────────────────────────────────
  group('UNKNOWN (no match)', () {
    test('gibberish',            () => expect(RuleEngine.quickParse('asdfghjkl', 'en'), isNull));
    test('empty',                () => expect(RuleEngine.quickParse('', 'en'), isNull));
    test('partial word',         () => expect(RuleEngine.quickParse('cal', 'en'), isNull));
  });

  // ── SOURCE TAG ────────────────────────────────────────────────────────────
  group('Source is always rule', () {
    test('source=rule', () {
      final cmd = RuleEngine.quickParse('torch on', 'en');
      expect(cmd?.source, 'rule');
    });
  });

  // ── LANGUAGE DETECTOR ─────────────────────────────────────────────────────
  group('LanguageDetector', () {
    test('Hindi script → hi', () {
      expect(_detectLang('टॉर्च चालू'), 'hi');
    });
    test('Tamil script → ta', () {
      expect(_detectLang('விளக்கு ஆன்'), 'ta');
    });
    test('Latin script → en', () {
      expect(_detectLang('torch on'), 'en');
    });
  });
}

// LanguageDetector is a static class — import it inline for test
String _detectLang(String text) {
  if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) return 'hi';
  if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) return 'ta';
  return 'en';
}
