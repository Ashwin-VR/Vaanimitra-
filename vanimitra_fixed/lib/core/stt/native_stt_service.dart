import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'stt_service.dart';

class NativeSttService extends SttService {
  static final instance = NativeSttService._();
  NativeSttService._();

  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _ready = false;
  bool _isMuted = false; // Set true during TTS to prevent feedback loop

  // ─── Initialize ───────────────────────────────────────────────────────────
  @override
  Future<bool> initialize() async {
    _ready = await _stt.initialize(
      onError: (_) {},
      onStatus: (_) {},
      debugLogging: false,
    );
    return _ready;
  }

  /// Call this BEFORE TTS speaks — prevents STT picking up speaker audio.
  void mute() => _isMuted = true;

  /// Call this AFTER TTS finishes — re-enables listening.
  void unmute() => _isMuted = false;

  // ─── Listen ───────────────────────────────────────────────────────────────
  @override
  Future<String?> listen({
    required String localeId,
    Duration listenFor = const Duration(seconds: 8),
  }) async {
    if (!_ready || _isMuted) return null;

    final completer = Completer<String?>();
    if (_stt.isListening) await stop();

    String partial = '';

    await _stt.listen(
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: const Duration(seconds: 2),
      partialResults: false,
      cancelOnError: true,
      // CRITICAL: offline only — do not use cloud speech recognition
      // This requires the device to have offline speech pack installed.
      // If not installed, results will still come but from cloud.
      onResult: (SpeechRecognitionResult result) {
        if (result.recognizedWords.isNotEmpty) {
          partial = result.recognizedWords;
        }
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(partial.trim().isEmpty ? null : partial.trim());
        }
      },
      onSoundLevelChange: null,
    );

    // Hard timeout — never hang
    Future.delayed(listenFor + const Duration(seconds: 1), () {
      if (!completer.isCompleted) {
        completer.complete(partial.trim().isEmpty ? null : partial.trim());
        _stt.stop();
      }
    });

    return completer.future;
  }

  // ─── Stop ─────────────────────────────────────────────────────────────────
  @override
  Future<void> stop() async {
    try { await _stt.stop(); } catch (_) {}
  }

  // ─── State ────────────────────────────────────────────────────────────────
  @override
  bool get isListening => _stt.isListening;

  @override
  bool get isAvailable => _ready;

  /// Returns true if device has an offline speech pack for the given locale.
  /// Used to show offline setup guidance if missing.
  Future<bool> hasOfflineLocale(String localeId) async {
    if (!_ready) return false;
    try {
      final locales = await _stt.locales();
      return locales.any((l) => l.localeId.startsWith(localeId.split('_')[0]));
    } catch (_) {
      return false;
    }
  }

  /// Returns list of available locale IDs on device.
  Future<List<String>> availableLocales() async {
    if (!_ready) return [];
    try {
      final locales = await _stt.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (_) {
      return [];
    }
  }
}
