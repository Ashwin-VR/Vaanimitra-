import 'dart:async';
// import 'package:porcupine_flutter/porcupine_flutter.dart'; // Disabled for now
// import 'package:porcupine_flutter/porcupine_error.dart';

class WakeWordService {
  static final instance = WakeWordService._internal();
  WakeWordService._internal();

  // PorcupineManager? _manager;
  Function()? onWakeWordDetected;

  bool _running = false;

  // ─── Start ────────────────────────────────────────────────────────────────
  Future<void> start() async {
    // STUB: Wake word disabled to unblock build.
    // Use manual mic button in the UI.
    _running = true;
  }

  // ─── Stop ─────────────────────────────────────────────────────────────────
  Future<void> stop() async {
    _running = false;
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────
  Future<void> dispose() async {
    await stop();
  }
}
