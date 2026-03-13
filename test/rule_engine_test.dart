import 'package:flutter_test/flutter_test.dart';
import 'package:vanimitra/core/llm/rule_engine.dart';
import 'package:vanimitra/models/v_intent.dart';

void main() {
  group('RuleEngine - Flashlight', () {
    test('English: torch on', () {
      final cmd = RuleEngine.quickParse('torch on', 'en');
      expect(cmd?.intent, VIntent.flashlightOn);
    });

    test('Hindi: टॉर्च चालू', () {
      final cmd = RuleEngine.quickParse('टॉर्च चालू', 'hi');
      expect(cmd?.intent, VIntent.flashlightOn);
    });

    test('Tamil: விளக்கு ஆன்', () {
      final cmd = RuleEngine.quickParse('விளக்கு ஆன்', 'ta');
      expect(cmd?.intent, VIntent.flashlightOn);
    });

    test('English: flashlight off', () {
      final cmd = RuleEngine.quickParse('flashlight off', 'en');
      expect(cmd?.intent, VIntent.flashlightOff);
    });

    test('Hindi: टॉर्च बंद', () {
      final cmd = RuleEngine.quickParse('टॉर्च बंद', 'hi');
      expect(cmd?.intent, VIntent.flashlightOff);
    });
  });

  group('RuleEngine - Volume', () {
    test('English: volume up', () {
      final cmd = RuleEngine.quickParse('volume up', 'en');
      expect(cmd?.intent, VIntent.volumeUp);
    });

    test('Hindi: आवाज़ बढ़ाओ', () {
      final cmd = RuleEngine.quickParse('आवाज़ बढ़ाओ', 'hi');
      expect(cmd?.intent, VIntent.volumeUp);
    });

    test('Tamil: ஒலி அதிகரி', () {
      final cmd = RuleEngine.quickParse('ஒலி அதிகரி', 'ta');
      expect(cmd?.intent, VIntent.volumeUp);
    });
  });

  group('RuleEngine - Call Contact', () {
    test('English: call John Doe', () {
      final cmd = RuleEngine.quickParse('call John Doe', 'en');
      expect(cmd?.intent, VIntent.callContact);
      expect(cmd?.params['contact'], 'john doe');
    });

    test('Hindi: राहुल को कॉल करो', () {
      final cmd = RuleEngine.quickParse('कॉल करो राहुल', 'hi');
      expect(cmd?.intent, VIntent.callContact);
      expect(cmd?.params['contact'], 'राहुल');
    });

    test('Tamil: அழை அருண்', () {
      // "அழை அருண்" -> trigger is "அழை "
      final cmd = RuleEngine.quickParse('அழை அருண்', 'ta');
      expect(cmd?.intent, VIntent.callContact);
      expect(cmd?.params['contact'], 'அருண்');
    });
  });

  group('RuleEngine - Apps & Navigation', () {
    test('Open WhatsApp', () {
      final cmd = RuleEngine.quickParse('open WhatsApp', 'en');
      expect(cmd?.intent, VIntent.openApp);
      expect(cmd?.params['app'], 'whatsapp');
    });

    test('Navigate to Mumbai', () {
      final cmd = RuleEngine.quickParse('navigate to Mumbai', 'en');
      expect(cmd?.intent, VIntent.navigate);
      expect(cmd?.params['destination'], 'mumbai');
    });
  });

  group('RuleEngine - Alarms', () {
    test('Set alarm for 07:30', () {
      final cmd = RuleEngine.quickParse('set alarm for 07:30', 'en');
      expect(cmd?.intent, VIntent.setAlarm);
      expect(cmd?.params['time'], '07:30');
    });

    test('Alarm at 8 o clock', () {
      final cmd = RuleEngine.quickParse('alarm at 8 o clock', 'en');
      expect(cmd?.intent, VIntent.setAlarm);
      expect(cmd?.params['time'], '08:00');
    });
  });
}
