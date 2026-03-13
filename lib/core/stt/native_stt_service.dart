import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'stt_service.dart';

class NativeSttService extends SttService {
  static final instance = NativeSttService._();
  NativeSttService._();

  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _ready = false;

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

  // ─── Listen ───────────────────────────────────────────────────────────────
  /// Returns the final transcript string, or null on silence/timeout.
  @override
  Future<String?> listen({
    required String localeId,
    Duration listenFor = const Duration(seconds: 8),
  }) async {
    if (!_ready) return null;

    final completer = Completer<String?>();

    // Guard: only one listen session at a time
    if (_stt.isListening) await stop();

    String _partial = '';

    _stt.listen(
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: const Duration(seconds: 2),
      partialResults: false,
      cancelOnError: true,
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          _partial = result.recognizedWords;
        }
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(
            _partial.trim().isEmpty ? null : _partial.trim(),
          );
        }
      },
      onSoundLevelChange: null,
    );

    // Fallback timeout in case speech_to_text never fires finalResult
    Future.delayed(listenFor + const Duration(seconds: 1), () {
      if (!completer.isCompleted) {
        completer.complete(_partial.trim().isEmpty ? null : _partial.trim());
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
    } catch (_) {}
  }

  // ─── State ────────────────────────────────────────────────────────────────
  @override
  bool get isListening => _stt.isListening;

  @override
  bool get isAvailable => _ready;
}
