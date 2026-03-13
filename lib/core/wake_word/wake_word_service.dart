import 'dart:async';
import 'package:porcupine_flutter/porcupine_flutter.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import '../../app/secrets.dart';
import '../../app/constants.dart';

class WakeWordService {
  static final instance = WakeWordService._internal();
  WakeWordService._internal();

  PorcupineManager? _manager;
  Function()? onWakeWordDetected;

  int _lastTriggerMs = 0;
  bool _running = false;

  // ─── Start ────────────────────────────────────────────────────────────────
  Future<void> start() async {
    if (_running) return;
    try {
      _manager = await PorcupineManager.fromKeywordPaths(
        VSecrets.picovoiceAccessKey,
        [VConstants.wakeWordAsset],
        _handleWakeWord,
        sensitivities: [VConstants.wakeWordSensitivity],
        errorCallback: (PorcupineException e) {
          // Log silently — never crash
        },
      );
      await _manager!.start();
      _running = true;
    } on PorcupineException catch (_) {
      // Wake word unavailable — graceful degradation
    }
  }

  // ─── Stop (releases mic so STT can use it) ────────────────────────────────
  Future<void> stop() async {
    if (!_running) return;
    try {
      await _manager?.stop();
    } catch (_) {}
    _running = false;
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    try {
      await stop();
      await _manager?.delete();
    } catch (_) {}
    _manager = null;
  }

  // ─── Internal trigger handler ─────────────────────────────────────────────
  void _handleWakeWord(int keywordIndex) {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Debounce — ignore rapid double-triggers
    if (now - _lastTriggerMs < VConstants.wakeWordDebounceMs) return;
    _lastTriggerMs = now;
    onWakeWordDetected?.call();
  }
}
