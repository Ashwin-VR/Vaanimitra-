import 'package:flutter_test/flutter_test.dart';
import 'package:vanimitra/core/stt/language_detector.dart';

void main() {
  group('LanguageDetector', () {
    test('English detection', () {
      expect(LanguageDetector.detect('turn on the lights'), 'en');
      expect(LanguageDetector.detect('call john'), 'en');
    });

    test('Hindi detection (Devanagari)', () {
      expect(LanguageDetector.detect('टॉर्च चालू करो'), 'hi');
      expect(LanguageDetector.detect('आवाज़ बढ़ाओ'), 'hi');
    });

    test('Tamil detection (Script)', () {
      expect(LanguageDetector.detect('விளக்கு ஆன்'), 'ta');
      expect(LanguageDetector.detect('அழை அருண்'), 'ta');
    });

    test('Code-switching (Hindi + English)', () {
      // If Devanagari is present, it should detect Hindi
      expect(LanguageDetector.detect('John को कॉल करो'), 'hi');
    });

    test('Code-switching (Tamil + English)', () {
      // If Tamil script is present, it should detect Tamil
      expect(LanguageDetector.detect('அருண் call pannu'), 'ta');
    });
  });
}
