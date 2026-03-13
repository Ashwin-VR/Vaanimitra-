// lib/features/tts/tts_service.dart

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_strings.dart';

class TtsService {
  static final instance = TtsService._internal();
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _earconPlayer = AudioPlayer();

  // Tracks the in-flight completer so stop() can unblock it immediately
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

  /// Speaks a TtsStrings map entry resolved for the given language.
  Future<void> speak(Map<String, String> strings, String language) async {
    final text = TtsStrings.get(strings, language);
    await _speakText(text, language);
  }

  /// Speaks arbitrary dynamic text (contact names, times, etc.).
  Future<void> speakDynamic(String text, String language) async {
    await _speakText(text, language);
  }

  /// Combines a TtsStrings map entry with a dynamic suffix in ONE utterance.
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
      // ignore: unawaited_futures
      _earconPlayer.play(AssetSource('earcon/chime.mp3'));
    } catch (_) {
      // Earcon is non-critical — never let it crash the pipeline
    }
  }

  /// Stops ongoing speech and unblocks any awaiting caller immediately.
  Future<void> stop() async {
    // Unblock any in-flight _speakText so the pipeline doesn't hang
    _currentCompleter?.complete();
    _currentCompleter = null;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Internal helper — always awaits completion or 8-second timeout.
  Future<void> _speakText(String text, String language) async {
    if (text.trim().isEmpty) return;

    // If a previous utterance is still pending, unblock it cleanly
    _currentCompleter?.complete();

    final completer = Completer<void>();
    _currentCompleter = completer;

    try {
      _tts.setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      });

      // Also unblock if engine errors / language pack missing
      _tts.setErrorHandler((msg) {
        if (!completer.isCompleted) completer.complete();
      });

      await _tts.setLanguage(_localeMap[language] ?? 'en-IN');
      await _tts.speak(text);

      // 8-second hard timeout — ensures we NEVER hang the pipeline
      await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );
    } catch (_) {
      // Safety net: never let TTS errors propagate and kill the pipeline
      if (!completer.isCompleted) completer.complete();
    } finally {
      if (_currentCompleter == completer) _currentCompleter = null;
    }
  }
}
