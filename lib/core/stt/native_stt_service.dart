import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
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
    try {
      final bool available = await _stt.initialize(
        onStatus: (_) {}, // Kept simple as in original, or define a proper handler if needed
        onError: (SpeechRecognitionError error) {
          debugPrint('STT Error: ${error.errorMsg}');
          if (error.errorMsg.contains('error_no_match') || error.errorMsg.contains('error_speech_timeout')) {
             // Normal silence/no-match timeouts
          } else if (error.errorMsg.contains('error_network')) {
             // Should not happen with onDevice: true, but if it does, it implies model missing
          }
        },
        debugLogging: true,
      );

      _ready = available; // Update _ready based on initialization result

      if (!available) {
        // Inform the user about missing language packs or other issues
        // This is where you might show a dialog or a message to the user.
        // For example: print('STT not available. Check language packs or permissions.');
        return false;
      }
      return true;
    } catch (e) {
      // Handle any exceptions during initialization
      // For example: print('Error initializing STT: $e');
      _ready = false; // Ensure _ready is false if an error occurs
      return false;
    }
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
      partialResults: true,
      cancelOnError: true,
      onResult: (SpeechRecognitionResult result) {
        if (result.recognizedWords.isNotEmpty) {
          partial = result.recognizedWords;
          debugPrint('STT Partial: $partial');
        }
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(partial.trim().isEmpty ? null : partial.trim());
        }
      },
      onSoundLevelChange: null,
      onDevice: true,
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
    try {
      await _stt.stop();
      // Ensure we trigger the final result if it was pending
    } catch (_) {}
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
