import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vanimitra/core/stt/native_stt_service.dart';
import 'tts_strings.dart';

class TtsService {
  static final instance = TtsService._internal();
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _earconPlayer = AudioPlayer();
  Completer<void>? _currentCompleter;

  static const Map<String, String> _localeMap = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
  };

  Future<void> init() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(Map<String, String> strings, String language) async {
    final text = TtsStrings.get(strings, language);
    await _speakText(text, language);
  }

  Future<void> speakDynamic(String text, String language) async {
    await _speakText(text, language);
  }

  Future<void> speakComposed(
    Map<String, String> strings,
    String suffix,
    String language,
  ) async {
    final base = TtsStrings.get(strings, language);
    await _speakText('$base $suffix'.trim(), language);
  }

  /// Fire-and-forget earcon — does NOT await completion.
  Future<void> speakEarcon() async {
    try {
      _earconPlayer.play(AssetSource('earcon/chime.mp3'));
    } catch (_) {}
  }

  Future<void> stop() async {
    _currentCompleter?.complete();
    _currentCompleter = null;
    try { await _tts.stop(); } catch (_) {}
  }

  /// Core speak — MUTES STT before speaking, UNMUTES after.
  /// This is the fix for issue #9 (TTS→STT feedback loop).
  Future<void> _speakText(String text, String language) async {
    if (text.trim().isEmpty) return;

    // CRITICAL: mute STT so it can't pick up TTS audio
    NativeSttService.instance.mute();

    _currentCompleter?.complete();
    final completer = Completer<void>();
    _currentCompleter = completer;

    try {
      _tts.setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      });
      _tts.setErrorHandler((msg) {
        if (!completer.isCompleted) completer.complete();
      });

      await _tts.setLanguage(_localeMap[language] ?? 'en-IN');
      await _tts.speak(text);

      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {},
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete();
    } finally {
      if (_currentCompleter == completer) _currentCompleter = null;
      // CRITICAL: unmute STT only AFTER TTS fully finishes
      // Extra 400ms buffer so reverb/echo doesn't get picked up
      await Future.delayed(const Duration(milliseconds: 400));
      NativeSttService.instance.unmute();
    }
  }
}
