// DEV 3 — implement per PDR Section 10.2 (System TTS + audioplayers for earcon)
class TtsService {
  static final instance = TtsService._internal();
  TtsService._internal();

  static const Map<String, String> _localeMap = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
  };

  Future<void> init() async {
    // TODO: init flutter_tts — setVolume(1.0), setSpeechRate(0.45), setPitch(1.0)
    // TODO: _verifyLanguagePacks()
  }

  Future<void> speak(Map<String, String> strings, String language) async {
    // TODO: implement
  }

  Future<void> speakDynamic(String text, String language) async {
    // TODO: implement
  }

  Future<void> speakComposed(Map<String, String> strings, String suffix, String language) async {
    // TODO: implement — combines string + suffix in one utterance
  }

  Future<void> speakEarcon() async {
    // TODO: _earconPlayer.play(AssetSource('earcon/chime.mp3')) — fire and forget
  }

  Future<void> stop() async {}

  Future<bool> isLanguageAvailable(String language) async => true;
}
